import 'dart:convert';
import 'package:emkamed_1/utils/ip_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'dart:io';

@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }
  await _initializeMqttWithRetry(service);
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  service.on('updateIpAddress').listen((event) async {
    if (event != null && event['ip'] != null) {
      await _initializeMqttWithRetry(service, newIp: event['ip']);
    }
  });
}

Future<void> _initializeMqttWithRetry(ServiceInstance service,
    {String? newIp}) async {
  final String ipAddress = newIp ?? IpConfig.IP_ADDR;
  int retryCount = 0;
  const int maxRetries = 3;
  const Duration retryDelay = Duration(seconds: 5);

  while (retryCount < maxRetries) {
    try {
      final mqttClient = await _connectMqtt(ipAddress, service);
      if (mqttClient != null) {
        return;
      }
    } catch (e) {
      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(retryDelay);
      } else {
        service.invoke('mqtt_connection_failed', {
          'error': 'Failed to connect after $maxRetries attempts',
          'ip': ipAddress
        });
      }
    }
  }
}

Future<MqttServerClient?> _connectMqtt(
    String ipAddress, ServiceInstance service) async {
  try {
    if (!_isValidIpAddress(ipAddress)) {
      throw Exception('Invalid IP address format: $ipAddress');
    }

    final mqttClient = MqttServerClient(
        ipAddress, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    mqttClient.port = 1883;
    mqttClient.logging(on: false);
    mqttClient.keepAlivePeriod = 60;
    mqttClient.connectTimeoutPeriod = 10000;

    mqttClient.onConnected = () {
      service.invoke(
          'mqtt_connection_status', {'status': 'connected', 'ip': ipAddress});
    };

    mqttClient.onDisconnected = () {
      service.invoke('mqtt_connection_status',
          {'status': 'disconnected', 'ip': ipAddress});
    };

    mqttClient.onAutoReconnect = () {
      service.invoke('mqtt_connection_status',
          {'status': 'reconnecting', 'ip': ipAddress});
    };

    mqttClient.autoReconnect = true;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(
            'flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .keepAliveFor(60)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    mqttClient.connectionMessage = connMessage;
    await mqttClient.connect().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Connection timeout after 15 seconds');
      },
    );

    if (mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
      mqttClient.subscribe("flu/test", MqttQos.atLeastOnce);

      mqttClient.updates!
          .listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (var message in messages) {
          final MqttPublishMessage recMessage =
              message.payload as MqttPublishMessage;
          final String messageString = MqttPublishPayload.bytesToStringAsString(
              recMessage.payload.message);
          try {
            Map<String, dynamic> data = jsonDecode(messageString);
            service.invoke('mqtt_message', {'message': messageString});
          } catch (e) {}
        }
      });

      return mqttClient;
    } else {
      throw Exception('Failed to establish MQTT connection');
    }
  } on SocketException catch (e) {
    throw Exception(
        'Network error: Unable to connect to $ipAddress. Check if the IP address is correct and the broker is running.');
  } on TimeoutException catch (e) {
    throw Exception(
        'Connection timeout: Unable to connect to $ipAddress within 15 seconds.');
  } on NoConnectionException catch (e) {
    throw Exception('MQTT connection error: ${e.toString()}');
  } catch (e) {
    throw Exception(
        'Unexpected error connecting to MQTT broker at $ipAddress: ${e.toString()}');
  }
}

bool _isValidIpAddress(String ip) {
  final RegExp ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
  return ipRegex.hasMatch(ip);
}

class MqttService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.dashboard/mqtt_config');

  static Future<bool> initializeMqttNative() async {
    try {
      if (!_isValidIpAddress(IpConfig.IP_ADDR)) {
        return false;
      }

      await _methodChannel
          .invokeMethod('setBrokerIp', {'ip': IpConfig.IP_ADDR});
      return true;
    } on PlatformException catch (e) {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> updateBrokerIp(String newIp) async {
    try {
      if (!_isValidIpAddress(newIp)) {
        throw Exception('Invalid IP address format: $newIp');
      }

      await _methodChannel.invokeMethod('setBrokerIp', {'ip': newIp});
      final service = FlutterBackgroundService();
      service.invoke('updateIpAddress', {'ip': newIp});
    } on PlatformException catch (e) {
      rethrow;
    }
  }

  static Future<void> disconnectMqtt() async {
    try {
      await _methodChannel.invokeMethod('disconnectMqtt');
    } on PlatformException catch (e) {}
  }

  static Future<void> unsubscribeAllTopics() async {
    try {
      await _methodChannel.invokeMethod('unsubscribeAllTopics');
    } on PlatformException catch (e) {}
  }

  static Future<bool> initializeService() async {
    try {
      final service = FlutterBackgroundService();

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onBackgroundServiceStart,
          isForegroundMode: false,
          autoStart: true,
        ),
        iosConfiguration: IosConfiguration(),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> testConnection(String ipAddress) async {
    try {
      if (!_isValidIpAddress(ipAddress)) {
        throw Exception('Invalid IP address format');
      }

      final socket = await Socket.connect(ipAddress, 1883)
          .timeout(const Duration(seconds: 5));

      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive/hive.dart';
import '../models/live_data.dart';
import '../models/mqtt_message.dart';
import '../service_http/mqtt_service.dart';
import '../service_http/noti_service.dart';
import '../utils/ip_config.dart';

class MqttViewModel extends ChangeNotifier {
  static const EventChannel _eventChannel =
      EventChannel("com.example.dashboard/mqtt_event");

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final List<LiveData> _chartData = [];

  double _voltage = 0.0;
  double _current = 0.0;
  double _temperature = 0.0;
  double _power = 0.0;
  bool _hasReceivedData = false;

  // Connection status properties
  String _connectionStatus = 'Initializing';
  String _errorMessage = '';
  bool _isConnecting = false;
  DateTime? _lastMessageTime;

  Map<String, Map<String, double>> _thresholds = {
    'temperature': {'min': 10.0, 'max': 35.0},
    'voltage': {'min': 5.0, 'max': 5.5},
    'current': {'min': 0.50, 'max': 1.0},
    'power': {'min': 1.5, 'max': 6.0},
  };

  MqttViewModel() {
    _initializeNotifications();
    _loadThresholds();
    _initializeMqttWithErrorHandling();
  }
  double get voltage => _voltage;
  double get current => _current;
  double get temperature => _temperature;
  double get power => _power;
  String get connectionStatus => _connectionStatus;
  String get errorMessage => _errorMessage;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _connectionStatus.contains('Connected');
  DateTime? get lastMessageTime => _lastMessageTime;

  List<LiveData> get chartData {
    if (!_hasReceivedData) return [];
    return _chartData.where((data) => data.time.year > 2000).toList();
  }

  Future<void> _loadThresholds() async {
    var box = await Hive.openBox('settingsBox');
    var storedThresholds = box.get('thresholds');
    if (storedThresholds != null) {
      _thresholds = Map<String, Map<String, double>>.from(
        storedThresholds.map(
          (key, value) => MapEntry(
            key,
            Map<String, double>.from(value.map(
              (k, v) => MapEntry(k, v ?? _thresholds[key]![k]!),
            )),
          ),
        ),
      );
    }
    notifyListeners();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  void _initializeMqttWithErrorHandling() async {
    _setConnectionStatus('Initializing', isConnecting: true);

    try {
      bool nativeInitialized = await MqttService.initializeMqttNative();
      if (!nativeInitialized) {
        _setConnectionStatus('Failed',
            error: 'Failed to initialize MQTT service');
        return;
      }
      bool serviceInitialized = await MqttService.initializeService();
      if (!serviceInitialized) {
        _setConnectionStatus('Failed',
            error: 'Failed to initialize background service');
        return;
      }
      _listenToMqttMessages();
      _listenToBackgroundService();
      _setConnectionStatus('Connecting');
    } catch (e) {
      _setConnectionStatus('Error', error: 'Initialization failed: $e');
      debugPrint('MQTT initialization error: $e');
    }
  }

  void _listenToMqttMessages() {
    _eventChannel.receiveBroadcastStream().listen(
      (message) {
        try {
          if (message is String && message.contains('"status"')) {
            final statusData = jsonDecode(message);
            if (statusData['status'] == 'connected') {
              _setConnectionStatus('Connected');
            }
            return;
          }

          final data = jsonDecode(message);
          final mqttMessage = MqttMessage.fromJson(data);

          _voltage = mqttMessage.voltage;
          _current = mqttMessage.current;
          _temperature = mqttMessage.temperature;
          _power = _voltage * _current;

          _hasReceivedData = true;
          _lastMessageTime = DateTime.now();
          _setConnectionStatus('Connected');
          final now = DateTime.now();
          _chartData
              .add(LiveData(now, _voltage, _current, _temperature, _power));
          if (_chartData.length > 20) _chartData.removeAt(0);

          _checkThresholds();
          notifyListeners();
        } catch (e) {
          debugPrint('Error processing message: $e');
        }
      },
      onError: (error) {
        debugPrint('Error from event channel: $error');

        if (error is PlatformException) {
          switch (error.code) {
            case 'MqttConnectionError':
              _setConnectionStatus('Connection Error',
                  error: error.message ?? 'Unknown connection error');
              break;
            case 'MqttConnectionLost':
              _setConnectionStatus('Disconnected', error: 'Connection lost');
              break;
            case 'MqttClientError':
              _setConnectionStatus('Client Error',
                  error: error.message ?? 'MQTT client error');
              break;
            default:
              _setConnectionStatus('Error',
                  error: error.message ?? 'Unknown MQTT error');
          }
        } else {
          _setConnectionStatus('Error', error: 'Unexpected error: $error');
        }
      },
    );
  }

  void _listenToBackgroundService() {
    final service = FlutterBackgroundService();

    service.on('mqtt_connection_status').listen((event) {
      if (event != null) {
        final status = event['status'] as String;
        switch (status) {
          case 'connected':
            _setConnectionStatus('Connected (Background)');
            break;
          case 'disconnected':
            _setConnectionStatus('Disconnected');
            break;
          case 'reconnecting':
            _setConnectionStatus('Reconnecting');
            break;
        }
      }
    });

    service.on('mqtt_connection_failed').listen((event) {
      if (event != null) {
        _setConnectionStatus('Connection Failed',
            error:
                'Background service error: ${event['error']} (IP: ${event['ip']})');
      }
    });

    service.on('mqtt_message').listen((event) {
      if (event != null && event['message'] != null) {
        try {
          final message = event['message'] as String;
          final data = jsonDecode(message);
          final mqttMessage = MqttMessage.fromJson(data);

          _voltage = mqttMessage.voltage;
          _current = mqttMessage.current;
          _temperature = mqttMessage.temperature;
          _power = _voltage * _current;

          _hasReceivedData = true;
          _lastMessageTime = DateTime.now();
          _setConnectionStatus('Connected (Background)');

          final now = DateTime.now();
          _chartData
              .add(LiveData(now, _voltage, _current, _temperature, _power));

          if (_chartData.length > 20) _chartData.removeAt(0);

          _checkThresholds();
          notifyListeners();
        } catch (e) {
          debugPrint('Error processing background service message: $e');
        }
      }
    });
  }

  void _setConnectionStatus(String status,
      {String? error, bool isConnecting = false}) {
    _connectionStatus = status;
    _errorMessage = error ?? '';
    _isConnecting = isConnecting;
    notifyListeners();
  }

  Future<void> reconnect() async {
    _setConnectionStatus('Reconnecting', isConnecting: true);

    try {
      if (MqttService.testConnection != null) {
        bool canConnect = await MqttService.testConnection(IpConfig.IP_ADDR);
        if (!canConnect) {
          _setConnectionStatus('Connection Failed',
              error: 'Cannot reach MQTT broker at ${IpConfig.IP_ADDR}:1883');
          return;
        }
      }
      await MqttService.disconnectMqtt();
      await Future.delayed(Duration(seconds: 1));
      _initializeMqttWithErrorHandling();
    } catch (e) {
      _setConnectionStatus('Error', error: 'Reconnect failed: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await MqttService.disconnectMqtt();
      await MqttService.unsubscribeAllTopics();
      _setConnectionStatus('Disconnected');
    } catch (e) {
      debugPrint('Error during disconnect: $e');
      _setConnectionStatus('Disconnected',
          error: 'Disconnect completed with errors');
    }
  }

  Color getStatusColor() {
    switch (_connectionStatus) {
      case 'Connected':
      case 'Connected (Background)':
        return Colors.green;
      case 'Reconnecting':
      case 'Connecting':
        return Colors.orange;
      case 'Connection Error':
      case 'Connection Failed':
      case 'Error':
      case 'Client Error':
        return Colors.red;
      case 'Disconnected':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData getStatusIcon() {
    switch (_connectionStatus) {
      case 'Connected':
      case 'Connected (Background)':
        return Icons.wifi;
      case 'Reconnecting':
      case 'Connecting':
      case 'Initializing':
        return Icons.wifi_protected_setup;
      case 'Connection Error':
      case 'Connection Failed':
      case 'Error':
      case 'Client Error':
        return Icons.wifi_off;
      case 'Disconnected':
        return Icons.wifi_off;
      default:
        return Icons.help_outline;
    }
  }

  void _checkThresholds() {
    if (_voltage > _thresholds['voltage']!['max']!) {
      NotiService().showNotification(
        title: 'Alerte de tension',
        body: 'Tension élevée : ${_voltage.toStringAsFixed(2)} V',
      );
    } else if (_voltage < _thresholds['voltage']!['min']!) {
      NotiService().showNotification(
        title: 'Alerte de tension',
        body: 'Tension basse : ${_voltage.toStringAsFixed(2)} V',
      );
    }
    if (_current > _thresholds['current']!['max']!) {
      NotiService().showNotification(
        title: 'Alerte de courant',
        body: 'Courant élevé : ${_current.toStringAsFixed(2)} A',
      );
    } else if (_current < _thresholds['current']!['min']!) {
      NotiService().showNotification(
        title: 'Alerte de courant',
        body: 'Courant bas : ${_current.toStringAsFixed(2)} A',
      );
    }
    if (_temperature > _thresholds['temperature']!['max']!) {
      NotiService().showNotification(
        title: 'Alerte de température',
        body: 'Température élevée : ${_temperature.toStringAsFixed(2)} °C',
      );
    } else if (_temperature < _thresholds['temperature']!['min']!) {
      NotiService().showNotification(
        title: 'Alerte de température',
        body: 'Température basse : ${_temperature.toStringAsFixed(2)} °C',
      );
    }
    if (_power > _thresholds['power']!['max']!) {
      NotiService().showNotification(
        title: 'Alerte de consommation d\'énergie',
        body:
            'Consommation énergétique élevée : ${_power.toStringAsFixed(2)} W',
      );
    } else if (_power < _thresholds['power']!['min']!) {
      NotiService().showNotification(
        title: 'Alerte de consommation d\'énergie',
        body: 'Consommation énergétique basse : ${_power.toStringAsFixed(2)} W',
      );
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

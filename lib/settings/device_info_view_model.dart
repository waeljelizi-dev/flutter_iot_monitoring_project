import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive/hive.dart';
import '../models/device_model.dart';
import '../repository/device_repository.dart';
import '../widgets/round_snackbar.dart';

class DeviceInfoViewModel extends ChangeNotifier {
  final DeviceRepository _repository;

  DeviceInfoViewModel(this._repository);

  String macAddress = 'N/A';
  String ipAddress = 'N/A';
  bool isLinked = false;
  int? userId;

  Future<void> loadDeviceInfo() async {
    final device = await _repository.loadDeviceFromHive();

    if (device != null) {
      _setDeviceData(device);
    } else {
      var box = await Hive.openBox('userBox');
      final int? deviceId = box.get('deviceId');
      if (deviceId != null) {
        final fetchedDevice = await _repository.fetchDevice(deviceId);
        if (fetchedDevice != null) {
          await _repository.storeDeviceToHive(fetchedDevice);
          _setDeviceData(fetchedDevice);
        }
      }
    }

    notifyListeners();
  }

  Future<void> unlinkDevice(BuildContext context) async {
    var box = await Hive.openBox('userBox');
    final int? deviceId = box.get('deviceId');

    if (deviceId == null) {
      RoundSnackBar.show(
        context,
        "Aucun appareil lié trouvé.",
        color: Colors.red,
      );
      return;
    }

    final success = await _repository.unlinkDevice(deviceId);
    if (success) {
      const methodChannel = MethodChannel('com.example.dashboard/mqtt_config');

      try {
        // Disconnect MQTT on native side
        await methodChannel.invokeMethod('disconnectMqtt');
      } catch (e) {}
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      await _repository.clearDeviceFromHive();
      macAddress = 'N/A';
      ipAddress = 'N/A';
      isLinked = false;
      notifyListeners();
    } else {
      RoundSnackBar.show(
        context,
        "Échec de la dissociation de l'appareil.",
        color: Colors.red,
      );
    }
  }

  void _setDeviceData(Device device) {
    macAddress = device.macAddress;
    ipAddress = device.ipAddress;
    isLinked = device.linked;
    userId = device.userId;
  }
}

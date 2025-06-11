import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../models/device_model.dart';
import '../utils/ip_config.dart';

class DeviceRepository {
  Future<Device?> fetchDevice(int deviceId) async {
    final response = await http.get(Uri.parse('http://${IpConfig.IP_ADDR}:8000/device/$deviceId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Device.fromJson(data);
    }
    return null;
  }

  Future<Device?> linkDevice(String macAddress, int userId) async {
    final response = await http.post(
      Uri.parse('http://${IpConfig.IP_ADDR}:8000/devices/link'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'adresse_mac': macAddress,
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return Device.fromJson(data['device']);
      }
    } else if (response.statusCode == 403) {
      throw Exception("Cet appareil est déjà lié à un autre utilisateur.");
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erreur inconnue');
    }

    return null;
  }

  Future<bool> unlinkDevice(int deviceId) async {
    final response = await http.put(
      Uri.parse('http://${IpConfig.IP_ADDR}:8000/device/unlink/$deviceId'),
    );

    return response.statusCode == 200;
  }

  Future<void> storeDeviceToHive(Device device) async {
    var box = await Hive.openBox('userBox');
    await box.put('deviceId', device.id);
    await box.put('adresse_mac', device.macAddress);
    await box.put('adresse_ip', device.ipAddress);
    await box.put('linked', device.linked);
    await box.put('userId', device.userId);
  }

  Future<Device?> loadDeviceFromHive() async {
    var box = await Hive.openBox('userBox');
    if (box.containsKey('adresse_mac') && box.containsKey('adresse_ip')) {
      return Device(
        id: box.get('deviceId') ?? -1,
        macAddress: box.get('adresse_mac'),
        ipAddress: box.get('adresse_ip'),
        linked: box.get('linked') ?? false,
        userId: box.get('userId') ?? -1,
      );
    }
    return null;
  }

  Future<void> clearDeviceFromHive() async {
    var box = await Hive.openBox('userBox');
    await box.delete('deviceId');
    await box.delete('adresse_mac');
    await box.delete('adresse_ip');
    await box.put('linked', false);
  }
}

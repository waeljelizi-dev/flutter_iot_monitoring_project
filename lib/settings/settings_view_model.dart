import 'package:emkamed_1/utils/ip_config.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsViewModel extends ChangeNotifier {
  bool _isNotificationsEnabled = true;
  Map<String, Map<String, double>> _thresholds = {
    'temperature': {'min': 10.0, 'max': 35.0},
    'voltage': {'min': 5.0, 'max': 5.5},
    'current': {'min': 0.50, 'max': 1.0},
    'power': {'min': 1.5, 'max': 6.0},
  };

  bool get isNotificationsEnabled => _isNotificationsEnabled;
  Map<String, Map<String, double>> get thresholds => _thresholds;

  SettingsViewModel() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    var box = await Hive.openBox('settingsBox');
    _isNotificationsEnabled =
        box.get('notificationsEnabled', defaultValue: true);

    // Load thresholds from Hive or use defaults
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

  Future<void> updateNotificationPreference(bool value) async {
    var box = await Hive.openBox('settingsBox');
    await box.put('notificationsEnabled', value);
    _isNotificationsEnabled = value;
    notifyListeners();
  }

  Future<void> updateThresholds(Map<String, Map<String, double?>> newThresholds,
      {int? deviceId}) async {
    final validatedThresholds = <String, Map<String, double>>{};
    for (var param in newThresholds.keys) {
      final minValue =
          newThresholds[param]!['min'] ?? _thresholds[param]!['min']!;
      final maxValue =
          newThresholds[param]!['max'] ?? _thresholds[param]!['max']!;

      validatedThresholds[param] = {
        'min': minValue,
        'max': maxValue,
      };
      if (validatedThresholds[param]!['min']! >=
          validatedThresholds[param]!['max']!) {
        throw Exception('Min threshold must be less than max for $param');
      }
    }

    _thresholds = validatedThresholds;
    var box = await Hive.openBox('settingsBox');
    await box.put('thresholds', _thresholds);

    if (deviceId != null) {
      await _updateBackendThresholds(deviceId, _thresholds);
    }

    notifyListeners();
  }

  Future<void> resetThresholds({int? deviceId}) async {
    _thresholds = {
      'temperature': {'min': 10.0, 'max': 35.0},
      'voltage': {'min': 5.0, 'max': 5.5},
      'current': {'min': 0.50, 'max': 1.0},
      'power': {'min': 1.5, 'max': 6.0},
    };
    var box = await Hive.openBox('settingsBox');
    await box.put('thresholds', _thresholds);

    if (deviceId != null) {
      await _updateBackendThresholds(deviceId, _thresholds);
    }

    notifyListeners();
  }

  Future<void> _updateBackendThresholds(
      int deviceId, Map<String, Map<String, double>> thresholds) async {
    try {
      final response = await http.post(
        Uri.parse('http://${IpConfig.IP_ADDR}:8000/thresholds/$deviceId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'temperature': {
            'min': thresholds['temperature']!['min'],
            'max': thresholds['temperature']!['max']
          },
          'voltage': {
            'min': thresholds['voltage']!['min'],
            'max': thresholds['voltage']!['max']
          },
          'current': {
            'min': thresholds['current']!['min'],
            'max': thresholds['current']!['max']
          },
          'power': {
            'min': thresholds['power']!['min'],
            'max': thresholds['power']!['max']
          },
        }),
      );
      if (response.statusCode != 200) {}
    } catch (e) {}
  }
}

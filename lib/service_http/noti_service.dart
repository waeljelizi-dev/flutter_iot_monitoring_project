import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';

class NotiService {
  static final NotiService _instance = NotiService._internal();
  factory NotiService() => _instance;
  NotiService._internal();

  final FlutterLocalNotificationsPlugin _notificationPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Box? _settingsBox;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationPlugin.initialize(initSettings);
    _isInitialized = true;
    _settingsBox ??= await Hive.openBox('settingsBox');
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      bool isAndroid13 = await _isAndroid13OrHigher();
      if (isAndroid13) {
        var status = await Permission.notification.status;
        if (status.isDenied || status.isPermanentlyDenied) {
          var newStatus = await Permission.notification.request();
          if (newStatus.isDenied) {
          } else if (newStatus.isPermanentlyDenied) {
            openAppSettings();
          }
        }
      }
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    return Platform.isAndroid && (await _getAndroidSdkVersion()) >= 33;
  }

  Future<int> _getAndroidSdkVersion() async {
    try {
      return (await const MethodChannel('android_sdk_version')
              .invokeMethod<int>('getSdkInt')) ??
          0;
    } catch (e) {
      return 0;
    }
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notification',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<bool> _isNotificationsEnabled() async {
    _settingsBox ??=
        await Hive.openBox('settingsBox'); // Open only if not already opened
    return _settingsBox!.get('notificationsEnabled', defaultValue: true);
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    if (!_isInitialized) await initNotification();

    bool notificationsEnabled = await _isNotificationsEnabled();
    if (!notificationsEnabled) {
      return;
    }
    await _notificationPlugin.show(id, title, body, _notificationDetails());
  }
}

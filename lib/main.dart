import 'package:emkamed_1/splash/splash_view_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:emkamed_1/service_http/mqtt_service.dart';
import 'package:emkamed_1/service_http/noti_service.dart';
import 'package:emkamed_1/splash/splash_screen.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('userBox');
  await Hive.openBox('settingsBox');
  final notiService = NotiService();
  await notiService.requestPermissions();
  await notiService.initNotification();
  await MqttService.initializeMqttNative();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

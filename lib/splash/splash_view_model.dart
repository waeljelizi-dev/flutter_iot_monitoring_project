import 'package:emkamed_1/onbording/onboarding_pages.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../scan/qr_code_page.dart';
import '../utils/ip_config.dart';
import '../home/home_page.dart';
import '../login/login_page.dart';

class SplashViewModel extends ChangeNotifier {
  Future<void> checkUserStatus(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 3)); // Simulate splash delay
    final settingsBox = Hive.box('settingsBox');
    final onboardingDone =
        settingsBox.get('onboarding_done', defaultValue: false);

    final userBox = Hive.box('userBox');
    final String? username = userBox.get('username');
    final int userId = userBox.get('userId', defaultValue: 0);

    if (username != null && username.isNotEmpty && userId > 0) {
      final bool isLinked = userBox.get('linked', defaultValue: false);

      if (isLinked) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else {
        _navigateTo(context, QrCodePage(userId: userId));
      }
    } else if (!onboardingDone) {
      _navigateTo(context, const OnboardingPage());
    } else {
      _navigateTo(context, LoginPage());
    }
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}

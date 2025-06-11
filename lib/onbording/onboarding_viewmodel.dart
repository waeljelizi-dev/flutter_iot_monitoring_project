import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../login/login_page.dart';
import '../models/onboarding_model.dart';



class OnboardingViewModel extends ChangeNotifier {
  final PageController pageController = PageController();
  int currentPage = 0;

  final List<OnboardingModel> pages = [
    OnboardingModel(
      title: 'Facile à utiliser',
      description: 'Une interface simple et intuitive pour une utilisation sans effort.',
      imageAsset: 'assets/onboarding/easy_to_use.png',
    ),
    OnboardingModel(
      title: 'Consommation d\'énergie',
      description: 'Surveillez la tension, le courant et la puissance en temps réel.',
      imageAsset: 'assets/onboarding/monitoring.png',
    ),
    OnboardingModel(
      title: 'Restez informé',
      description: 'Recevez des notifications pour les événements critiques.',
      imageAsset: 'assets/onboarding/alerting.png',
    ),
  ];

  void updatePage(int index) {
    currentPage = index;
    notifyListeners();
  }

  Future<void> completeOnboarding(BuildContext context) async {
    final settingsBox = Hive.box('settingsBox');
    await settingsBox.put('onboarding_done', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) =>  LoginPage()),
    );
  }

  void nextPage(BuildContext context) {
    if (currentPage == pages.length - 1) {
      completeOnboarding(context);
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skip(BuildContext context) {
    completeOnboarding(context);
  }
}
import 'dart:io';

import 'package:emkamed_1/statistics/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../dashboard/mqtt_view_model.dart';
import '../settings/settings_page.dart';
import '../dashboard/mqtt_screen.dart';
import 'home_view_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HomeViewModel()),
          ChangeNotifierProvider(create: (_) => MqttViewModel()),
        ],
        child: Consumer<HomeViewModel>(
          builder: (context, homeViewModel, child) {
            return Scaffold(
              body: IndexedStack(
                index: homeViewModel.selectedIndex,
                children: [
                  MqttScreen(),
                  const StatisticsPage(),
                  SettingsPage(),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                backgroundColor: const Color(0xFF256C98),
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                currentIndex: homeViewModel.selectedIndex,
                onTap: homeViewModel.onItemTapped,
                items: [
                  _buildNavItem(
                      "assets/icons/dashboard.svg", "Tableau de bord"),
                  _buildNavItem("assets/icons/analysis.svg", "Statistique"),
                  _buildNavItem("assets/icons/settings.svg", "Paramètres"),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static BottomNavigationBarItem _buildNavItem(String iconPath, String label) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(iconPath,
          width: 24,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      activeIcon: SvgPicture.asset(iconPath,
          width: 24,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      label: label,
    );
  }
}

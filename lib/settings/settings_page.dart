import 'package:emkamed_1/settings/profile_page.dart';
import 'package:emkamed_1/settings/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../../settings/device_info_page.dart';
import '../../login/login_page.dart';
import '../utils/ip_config.dart';

class SettingsPage extends StatelessWidget {
  final TextEditingController ipAdress = TextEditingController();

  SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsViewModel(),
      child: Consumer<SettingsViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Paramètres",
                  style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF256C98),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: ListView(
              children: [
                _buildSectionHeader("Compte"),
                _buildSettingsTile(Icons.person, "Profile", onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ProfilePage()));
                }),
                _buildSectionHeader("Périphérique"),
                _buildSettingsTile(Icons.electrical_services, "Informations",
                    onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DeviceInfoPage()));
                }),
                _buildSectionHeader("Notifications"),
                _buildToggleTile(
                  Icons.notifications,
                  "Activer/désactiver alerts",
                  value: viewModel.isNotificationsEnabled,
                  onChanged: (val) =>
                      viewModel.updateNotificationPreference(val),
                ),
                _buildSectionHeader("Seuils"),
                _buildSettingsTile(Icons.tune, "Ajuster les seuils", onTap: () {
                  _showThresholdDialog(context, viewModel);
                }),
                _buildSectionHeader("A propos"),
                _buildSettingsTile(Icons.info, "À propos de l'application",
                    onTap: () => _showAboutDialog(context)),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text("Déconnexion",
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () => _showLogoutDialog(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showThresholdDialog(BuildContext context, SettingsViewModel viewModel) {
    final temperatureMinController = TextEditingController(
        text: viewModel.thresholds['temperature']!['min'].toString());
    final temperatureMaxController = TextEditingController(
        text: viewModel.thresholds['temperature']!['max'].toString());
    final voltageMinController = TextEditingController(
        text: viewModel.thresholds['voltage']!['min'].toString());
    final voltageMaxController = TextEditingController(
        text: viewModel.thresholds['voltage']!['max'].toString());
    final currentMinController = TextEditingController(
        text: viewModel.thresholds['current']!['min'].toString());
    final currentMaxController = TextEditingController(
        text: viewModel.thresholds['current']!['max'].toString());
    final powerMinController = TextEditingController(
        text: viewModel.thresholds['power']!['min'].toString());
    final powerMaxController = TextEditingController(
        text: viewModel.thresholds['power']!['max'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ajuster les seuils"),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
          actionsPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          content: SizedBox(
            width:
                MediaQuery.of(context).size.width * 0.9, // 90% of screen width
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThresholdInput("Température (°C)",
                      temperatureMinController, temperatureMaxController),
                  _buildThresholdInput("Tension (V)", voltageMinController,
                      voltageMaxController),
                  _buildThresholdInput("Courant (A)", currentMinController,
                      currentMaxController),
                  _buildThresholdInput(
                      "Puissance (W)", powerMinController, powerMaxController),
                ],
              ),
            ),
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Annuler"),
                    ),
                    TextButton(
                      onPressed: () async {
                        var box = await Hive.openBox('userBox');
                        final int? deviceId = box.get('deviceId');
                        viewModel.resetThresholds(deviceId: deviceId);
                      },
                      child: const Text("Réinitialiser"),
                    ),
                    TextButton(
                      onPressed: () async {
                        final newThresholds = <String, Map<String, double?>>{
                          'temperature': {
                            'min': double.tryParse(
                                    temperatureMinController.text) ??
                                viewModel.thresholds['temperature']!['min']!,
                            'max': double.tryParse(
                                    temperatureMaxController.text) ??
                                viewModel.thresholds['temperature']!['max']!,
                          },
                          'voltage': {
                            'min': double.tryParse(voltageMinController.text) ??
                                viewModel.thresholds['voltage']!['min']!,
                            'max': double.tryParse(voltageMaxController.text) ??
                                viewModel.thresholds['voltage']!['max']!,
                          },
                          'current': {
                            'min': double.tryParse(currentMinController.text) ??
                                viewModel.thresholds['current']!['min']!,
                            'max': double.tryParse(currentMaxController.text) ??
                                viewModel.thresholds['current']!['max']!,
                          },
                          'power': {
                            'min': double.tryParse(powerMinController.text) ??
                                viewModel.thresholds['power']!['min']!,
                            'max': double.tryParse(powerMaxController.text) ??
                                viewModel.thresholds['power']!['max']!,
                          },
                        };
                        try {
                          var box = await Hive.openBox('userBox');
                          final int? deviceId = box.get('deviceId');
                          viewModel.updateThresholds(newThresholds,
                              deviceId: deviceId);
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: ${e.toString()}')),
                          );
                        }
                      },
                      child: const Text("Enregistrer"),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildThresholdInput(String label, TextEditingController minController,
      TextEditingController maxController) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Min"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Max"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("À propos de l'application"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nom : Emkamed Monitor"),
              SizedBox(height: 8),
              Text("Version : JW.1.0.5"),
              SizedBox(height: 8),
              Text(
                  "Description : Cette application vous permet de surveiller en temps réel vos dispositifs électroniques connectés, en affichant la tension, le courant, la puissance et d'autres paramètres importants."),
              SizedBox(height: 8),
              Text("Developée dans le cadre du projet PFE L3TIC 2025."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: const Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Oui"),
              onPressed: () async {
                await _logout(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    var userBox = await Hive.openBox('userBox');
    const methodChannel = MethodChannel('com.example.dashboard/mqtt_config');

    try {
      await methodChannel.invokeMethod('unsubscribeAllTopics');
      await methodChannel.invokeMethod('disconnectMqtt');
    } catch (e) {
      debugPrint("MQTT disconnect error: $e");
    }

    await userBox.clear();
    await userBox.close();

    final service = FlutterBackgroundService();
    service.invoke('stopService');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF256C98)),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(
    IconData icon,
    String title, {
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF256C98)),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF256C98),
        activeTrackColor: const Color(0xFF256C98).withOpacity(0.5),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withOpacity(0.5),
      ),
    );
  }
}

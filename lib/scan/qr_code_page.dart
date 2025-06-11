import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';

import '../../repository/device_repository.dart';
import '../../scan/qr_code_view_model.dart';
import '../../login/login_page.dart';
import '../../settings/profile_page.dart'; // Import your profile page

class QrCodePage extends StatelessWidget {
  final int userId;

  const QrCodePage({Key? key, required this.userId}) : super(key: key);

  void _logout(BuildContext context) async {
    var box = await Hive.openBox('userBox');
    await box.clear();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<QrCodeViewModel>(
      create: (_) =>
          QrCodeViewModel(repository: DeviceRepository(), userId: userId),
      child: Consumer<QrCodeViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Associer un périphérique",
                  style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF256C98),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: () => _navigateToProfile(context),
                  tooltip: 'Profile',
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => _logout(context),
                  tooltip: 'Déconnexion',
                ),
              ],
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(child: Image.asset('assets/link2.png', width: 200)),
                const SizedBox(height: 20),
                const Text(
                  "Aucun appareil lié.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (viewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.link, color: Colors.white),
                  label: const Text(
                    "Associer un périphérique",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF256C98).withOpacity(0.8),
                  ),
                  onPressed: () => viewModel.scanQRCode(context),
                ),
                if (viewModel.isScanning)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

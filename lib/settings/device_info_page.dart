import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/device_repository.dart';
import '../scan/qr_code_page.dart';
import 'device_info_view_model.dart';

class DeviceInfoPage extends StatelessWidget {
  const DeviceInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DeviceInfoViewModel>(
      create: (_) {
        final repository = DeviceRepository();
        final viewModel = DeviceInfoViewModel(repository);
        viewModel.loadDeviceInfo();
        return viewModel;
      },
      child: Consumer<DeviceInfoViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                "Informations",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF256C98),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: viewModel.macAddress == 'N/A' && viewModel.ipAddress == 'N/A'
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      ListTile(
                        title: const Text('Adresse MAC'),
                        subtitle: Text(viewModel.macAddress),
                      ),
                      ListTile(
                        title: const Text('Adresse IP'),
                        subtitle: Text(viewModel.ipAddress),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: viewModel.isLinked
                            ? () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title:
                                        const Text('Confirmer la dissociation'),
                                    content: const Text(
                                        'Êtes-vous sûr de vouloir dissocier ce périphérique ?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Annuler'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Confirmer'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  await viewModel.unlinkDevice(context);
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => QrCodePage(
                                            userId: viewModel.userId!),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF256C98),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(viewModel.isLinked
                            ? 'Dissocier'
                            : "Périphérique n'est pas associé"),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

import 'package:emkamed_1/scan/qr_code_scanner_page.dart';
import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../repository/device_repository.dart';
import '../home/home_page.dart';

class QrCodeViewModel extends ChangeNotifier {
  final DeviceRepository _repository;
  final int userId;

  QrCodeViewModel({required DeviceRepository repository, required this.userId})
      : _repository = repository;

  bool isScanning = false;
  String? errorMessage;

  Future<void> scanQRCode(BuildContext context) async {
    isScanning = true;
    notifyListeners();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QRScannerPage()),
    );

    if (result != null) {
      if (_isValidMacAddress(result)) {
        await _linkDevice(result, context);
      } else {
        errorMessage = "QR Code invalide ! Ce n'est pas une adresse MAC.";
        _showErrorDialog(context, errorMessage!);
      }
    }

    isScanning = false;
    notifyListeners();
  }

  Future<void> _linkDevice(String macAddress, BuildContext context) async {
    try {
      final device = await _repository.linkDevice(macAddress, userId);
      if (device != null) {
        await _repository.storeDeviceToHive(device);
        errorMessage = null;

        if (context.mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomePage()));
        }
      }
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
      _showErrorDialog(context, errorMessage!);
    }
  }

  bool _isValidMacAddress(String macAddress) {
    final RegExp macRegex = RegExp(
      r'^[0-9A-Fa-f]{2}([:-])[0-9A-Fa-f]{2}\1[0-9A-Fa-f]{2}\1[0-9A-Fa-f]{2}\1[0-9A-Fa-f]{2}\1[0-9A-Fa-f]{2}$',
    );
    return macRegex.hasMatch(macAddress);
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Erreur"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

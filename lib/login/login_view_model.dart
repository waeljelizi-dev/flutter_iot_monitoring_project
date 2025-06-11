import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/device_model.dart';
import '../scan/qr_code_page.dart';
import '../home/home_page.dart';
import '../repository/user_repository.dart';
import '../service_http/mqtt_service.dart';
import '../widgets/round_snackbar.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final UserRepository _userRepo = UserRepository();

  bool isLoading = false;
  User? currentUser;
  Device? currentDevice;

  Future<void> handleLogin(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    final username = loginController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      RoundSnackBar.show(context, "Veuillez remplir tous les champs",
          color: Colors.orange);
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await _userRepo.login(username, password);

      if (response.containsKey('error')) {
        RoundSnackBar.show(context, response['error'], color: Colors.red);
      } else {
        currentUser = User.fromJson(response['user']);
        currentDevice = response['device'] != null
            ? Device.fromJson(response['device'])
            : null;

        await _userRepo.saveUserAndDevice(currentUser!, currentDevice);

        RoundSnackBar.show(context, "Connexion réussie!", color: Colors.green);

        if (currentDevice?.linked == true) {
          // await MqttService.initializeService();
          Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => HomePage()), (route) => false);
        } else {
          //Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QrCodePage(userId: currentUser!.id ?? 0)));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => QrCodePage(userId: currentUser!.id ?? 0),
            ),
            (route) => false,
          );
        }
      }
    } on TimeoutException {
      RoundSnackBar.show(
          context, "Temps de réponse dépassé. Vérifiez votre connexion.",
          color: Colors.red);
    } catch (e) {
      RoundSnackBar.show(context, "Erreur de connexion: $e", color: Colors.red);
    }

    isLoading = false;
    notifyListeners();
  }

  bool isFormValid() {
    return loginController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;
  }
}

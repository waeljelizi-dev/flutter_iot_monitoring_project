import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../repository/user_repository.dart';
import '../widgets/round_snackbar.dart';

class EditProfileViewModel extends ChangeNotifier {
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final UserRepository _userRdepository;
  bool isPasswordVisible = false;
  EditProfileViewModel(
      String currentUsername,
      String currentEmail, {
        UserRepository? userRepository,
      }) : _userRepository = userRepository ?? UserRepository() {
    usernameController = TextEditingController(text: currentUsername);
    emailController = TextEditingController(text: currentEmail);
    passwordController = TextEditingController();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  Future<void> updateProfile(
      BuildContext context, Function(String, String, String) onUpdate) async {
    if (!formKey.currentState!.validate()) return;

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || email.isEmpty) {
      RoundSnackBar.show(
        context,
        "Nom d'utilisateur et email sont requis.",
        color: Colors.orange,
      );
      return;
    }

    if (!_isValidEmail(email)) {
      RoundSnackBar.show(
        context,
        "Format d'email invalide.",
        color: Colors.orange,
      );
      return;
    }

    var box = await Hive.openBox('userBox');
    int? userId = box.get('userId');

    if (userId == null) {
      RoundSnackBar.show(
        context,
        "User ID not found in Hive storage.",
        color: Colors.orange,
      );
      return;
    }

    final newPassword = password.isEmpty ? null : password;

    final response = await _userRepository.updateProfile(
      userId: userId,
      username: username,
      email: email,
      password: newPassword,
    );

    if (response.statusCode == 400) {
      final body = jsonDecode(response.body);
      final error = body['error'] ?? "Erreur inconnue";
      RoundSnackBar.show(
        context,
        error,
        color: Colors.red,
      );
    }else if (response.statusCode == 200) {
      await box.put('username', username);
      await box.put('email', email);
      if (newPassword != null) await box.put('password', newPassword);

      onUpdate(username, email, newPassword ?? box.get('password'));

      Navigator.pop(context);
      RoundSnackBar.show(
        context,
        "votre compte est mis a jour",
        color: Colors.green,
      );
    } else {
      RoundSnackBar.show(
        context,
        "Échec de la mise à jour du profil.",
        color: Colors.red,
      );
    }
  }
  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

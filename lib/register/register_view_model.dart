import 'dart:async';
import 'package:flutter/material.dart';
import '../repository/user_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  String? warningMessage;

  // Email validation regex
  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );

  // Method to validate email
  bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }

  Future<void> registerUser(BuildContext context, String username,
      String password, String email) async {
    // Check if any field is empty
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      warningMessage = "Veuillez remplir tous les champs";
      notifyListeners();
      return;
    }

    // Validate email format
    if (!isValidEmail(email)) {
      warningMessage = "Veuillez entrer une adresse email valide";
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    successMessage = null;
    warningMessage = null;
    notifyListeners();

    try {
      final result = await _userRepo.register(username, password, email);

      if (result.containsKey('message')) {
        await _userRepo.saveBasicInfo(username, email);

        successMessage = result["message"];
        notifyListeners();

        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
      } else if (result.containsKey('error')) {
        errorMessage = result["error"];
        notifyListeners();
      } else {
        errorMessage = "Erreur inconnue lors de l'inscription";
        notifyListeners();
      }
    } catch (e) {
      errorMessage = e is TimeoutException
          ? e.message
          : "Erreur lors de l'inscription: ${e.toString()}";
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    warningMessage = null;
    notifyListeners();
  }
}

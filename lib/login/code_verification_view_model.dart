import 'package:flutter/material.dart';
import '../repository/user_repository.dart';

class CodeVerificationViewModel extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  bool isLoading = false;
  String? error;

  Future<bool> verifyCode(String email, String code) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final response = await _userRepository.verifyCode(email, code);
      isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return true;
      } else {
        error = "Code incorrect. Essayez encore.";
        return false;
      }
    } catch (e) {
      isLoading = false;
      error = "Erreur réseau";
      notifyListeners();
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import '../../repository/user_repository.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  ResetPasswordViewModel({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<String?> resetPassword({
    required String email,
    required String pass1,
    required String pass2,
  }) async {
    if (pass1 != pass2) {
      return "Les mots de passe ne correspondent pas.";
    }
    if (pass1.isEmpty || pass2.isEmpty) {
      return "Veuillez tapper votre mot de passe.";
    }

    _setLoading(true);
    try {
      final response = await _userRepository.resetPassword(email, pass1);

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return "Erreur lors de la réinitialisation.";
      }
    } catch (e) {
      return "Erreur réseau : $e";
    } finally {
      _setLoading(false);
    }
  }
}

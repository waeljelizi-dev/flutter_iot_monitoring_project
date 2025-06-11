import 'package:emkamed_1/login/code_verification_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../repository/user_repository.dart';
import '../widgets/round_snackbar.dart';
import 'code_verification_view_model.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final UserRepository _userRepository = UserRepository();

  bool isLoading = false;
  String? message;
  bool emailExists = false;
  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );
  bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }

  Future<void> sendResetRequest(BuildContext context) async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      RoundSnackBar.show(
        context,
        "Veuillez entrer votre adresse email.",
        color: Colors.orange,
      );
      return;
    }
    if (!isValidEmail(email)) {
      RoundSnackBar.show(
        context,
        "Veuillez entrer une adresse email valide.",
        color: Colors.orange,
      );
      return;
    }

    isLoading = true;
    message = null;
    notifyListeners();

    try {
      final response = await _userRepository.sendResetPasswordEmail(email);

      isLoading = false;

      if (response.statusCode == 200) {
        emailExists = true;
        notifyListeners();
        Navigator.of(context).pop();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ChangeNotifierProvider(
            create: (_) => CodeVerificationViewModel(),
            child: CodeVerificationDialog(email: email),
          ),
        );
      } else if (response.statusCode == 404) {
        emailExists = false;
        notifyListeners();
        RoundSnackBar.show(
          context,
          "Email n'existe pas dans la base.",
          color: Colors.red,
        );
      } else {
        RoundSnackBar.show(
          context,
          "Erreur serveur.",
          color: Colors.red,
        );
      }
    } catch (e) {
      isLoading = false;
      RoundSnackBar.show(
        context,
        "Erreur réseau.",
        color: Colors.red,
      );
    }
  }
}

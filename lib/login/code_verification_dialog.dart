import 'package:emkamed_1/login/code_verification_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/round_snackbar.dart';
import 'reset_password_dialog.dart';

class CodeVerificationDialog extends StatefulWidget {
  final String email;
  const CodeVerificationDialog({super.key, required this.email});

  @override
  State<CodeVerificationDialog> createState() => _CodeVerificationDialogState();
}

class _CodeVerificationDialogState extends State<CodeVerificationDialog> {
  final List<TextEditingController> _controllers =
      List.generate(5, (_) => TextEditingController());

  String get fullCode => _controllers.map((e) => e.text).join();

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = fullCode;
    if (code.length != 5) return;

    final viewModel = context.read<CodeVerificationViewModel>();
    final success = await viewModel.verifyCode(widget.email, code);

    if (success) {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ResetPasswordDialog(email: widget.email),
      );
    } else {
      final error = viewModel.error ?? "Erreur inconnue.";
      RoundSnackBar.show(
        context,
        error,
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CodeVerificationViewModel>();

    return AlertDialog(
      title: Text("Vérification du code"),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          5,
          (index) => SizedBox(
            width: 40,
            child: TextField(
              controller: _controllers[index],
              maxLength: 1,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(counterText: ""),
              onChanged: (val) {
                if (val.isNotEmpty && index < 4) {
                  FocusScope.of(context).nextFocus();
                }
              },
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF256C98),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: viewModel.isLoading ? null : _submitCode,
          child: viewModel.isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Text("Valider"),
        )
      ],
    );
  }
}

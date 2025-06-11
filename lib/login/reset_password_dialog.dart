import 'package:emkamed_1/widgets/round_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../login/reset_password_view_model.dart';

class ResetPasswordDialog extends StatefulWidget {
  final String email;
  const ResetPasswordDialog({super.key, required this.email});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final TextEditingController pass1 = TextEditingController();
  final TextEditingController pass2 = TextEditingController();
  bool isPassword1Visible = false;
  bool isPassword2Visible = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ResetPasswordViewModel(),
      child: Consumer<ResetPasswordViewModel>(
        builder: (context, viewModel, _) {
          return AlertDialog(
            title: Text("Nouveau mot de passe"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pass1,
                  obscureText: !isPassword1Visible,
                  decoration: InputDecoration(
                    labelText: "Nouveau mot de passe",
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPassword1Visible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Color(0xFF256C98),
                      ),
                      onPressed: () {
                        setState(() {
                          isPassword1Visible = !isPassword1Visible;
                        });
                      },
                    ),
                  ),
                ),
                TextField(
                  controller: pass2,
                  obscureText: !isPassword2Visible,
                  decoration: InputDecoration(
                    labelText: "Confirmer le mot de passe",
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPassword2Visible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Color(0xFF256C98),
                      ),
                      onPressed: () {
                        setState(() {
                          isPassword2Visible = !isPassword2Visible;
                        });
                      },
                    ),
                  ),
                ),
                if (viewModel.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF256C98),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                        final error = await viewModel.resetPassword(
                          email: widget.email,
                          pass1: pass1.text,
                          pass2: pass2.text,
                        );
                        if (error == null) {
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close dialog
                            /*ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Mot de passe réinitialisé avec succès !")),
                      );*/
                            RoundSnackBar.show(
                              context,
                              "Mot de passe réinitialisé avec succès !",
                              color: Colors.green,
                            );
                          }
                        } else {
                          if (context.mounted) {
                            /*ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );*/
                            RoundSnackBar.show(
                              context,
                              error,
                              color: Colors.red,
                            );
                          }
                        }
                      },
                child: Text("Réinitialiser"),
              ),
            ],
          );
        },
      ),
    );
  }
}

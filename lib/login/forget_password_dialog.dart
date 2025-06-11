import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'forget_password_view_model.dart';

class ForgotPasswordDialog extends StatelessWidget {
  const ForgotPasswordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordViewModel(),
      child: Consumer<ForgotPasswordViewModel>(
        builder: (context, viewModel, _) {
          return AlertDialog(
            title: Text("Mot de passe oublié"),
            content: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // To make the dialog compact
                children: [
                  Text("Entrez votre adresse email pour réinitialiser votre mot de passe."),
                  TextField(
                    controller: viewModel.emailController,
                    decoration: InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF256C98),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: viewModel.isLoading ? null : () => viewModel.sendResetRequest(context),
                    child: viewModel.isLoading
                        ? CircularProgressIndicator()
                        : Text("Envoyer"),
                  ),
                  if (viewModel.message != null) ...[
                    SizedBox(height: 20),
                    Text(viewModel.message!, style: TextStyle(color: Colors.green)),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

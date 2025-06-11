import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../register/register_view_model.dart';
import '../widgets/my_text_field.dart';
import '../widgets/round_snackbar.dart';


class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RegisterViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFF256C98),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/connection.png",
                        height: 180,
                        width: 180,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Créer un compte'.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      MyTextField(
                          controller: usernameController,
                        hintText: "Nom d'utilisateur",
                          isPassword: false,
                      )
                      const SizedBox(height: 15),
                      MyTextField(
                        controller: emailController,
                        hintText: "Email",
                        isPassword: false,
                      )
                      const SizedBox(height: 15),
                      MyTextField(
                        controller: passwordController,
                        hintText: "Mot de passe",
                        isPassword: true,
                      )
                      const SizedBox(height: 20),
                      Consumer<RegisterViewModel>(
                        builder: (context, viewModel, child) {
                          return ElevatedButton(
                            onPressed: viewModel.isLoading
                                ? null
                                : () {
                              viewModel.registerUser(context,
                                usernameController.text.trim(),
                                passwordController.text.trim(),
                                emailController.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF256C98),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: viewModel.isLoading
                                ? Lottie.asset(
                              'assets/loader_2.json',
                              height: 50,
                            )
                                : const Text(
                              "S'INSCRIRE",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      Consumer<RegisterViewModel>(
                        builder: (context, viewModel, child) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (viewModel.errorMessage != null) {
                              RoundSnackBar.show(context, viewModel.errorMessage!, color: Colors.red);
                              viewModel.clearMessages();
                            } else if (viewModel.successMessage != null) {
                              RoundSnackBar.show(context, viewModel.successMessage!, color: Colors.green);
                              viewModel.clearMessages();
                            } else if (viewModel.warningMessage != null) {
                              RoundSnackBar.show(context, viewModel.warningMessage!, color: Colors.orange);
                              viewModel.clearMessages();
                            }
                          });

                          return const SizedBox.shrink(); // Empty widget to avoid UI disruption
                        },
                      ),

                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Vous avez déjà un compte?",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Se connecter",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

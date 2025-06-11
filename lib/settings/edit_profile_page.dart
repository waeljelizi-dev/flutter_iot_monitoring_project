/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/edit_profile_view_model.dart';


class EditProfilePage extends StatelessWidget {
  final String currentUsername;
  final String currentEmail;
  final String currentPassword;
  final Function(String, String, String) onUpdate;

  EditProfilePage({
    required this.currentUsername,
    required this.currentEmail,
    required this.currentPassword,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditProfileViewModel(currentUsername, currentEmail),
      child: Consumer<EditProfileViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Editer profile", style: TextStyle(color: Colors.white)),
              backgroundColor: Color(0xFF256C98),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: viewModel.formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: viewModel.usernameController,
                      decoration: InputDecoration(labelText: 'Nom utilisateur'),
                      validator: (value) => value!.isEmpty ? 'Enter le nouveau nom utilisateur' : null,
                    ),
                    TextFormField(
                      controller: viewModel.emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (value) => value!.isEmpty ? 'Enter le nouveau email' : null,
                    ),
                    TextFormField(
                      controller: viewModel.passwordController,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe (Optional)',
                        suffixIcon: IconButton(
                          icon: Icon(
                            viewModel.isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Color(0xFF256C98),
                          ),
                          onPressed: () {
                            viewModel.togglePasswordVisibility();
                          },
                        ),
                      ),
                      obscureText: !viewModel.isPasswordVisible,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF256C98),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () => viewModel.updateProfile(context, onUpdate),
                      child: Text('Sauvegarder'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
*/


import 'package:emkamed_1/widgets/my_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/edit_profile_view_model.dart';


class EditProfilePage extends StatelessWidget {
  final String currentUsername;
  final String currentEmail;
  final String currentPassword;
  final Function(String, String, String) onUpdate;

  EditProfilePage({
    required this.currentUsername,
    required this.currentEmail,
    required this.currentPassword,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditProfileViewModel(currentUsername, currentEmail),
      child: Consumer<EditProfileViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Editer profile", style: TextStyle(color: Colors.white)),
              backgroundColor: Color(0xFF256C98),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: viewModel.formKey,
                child: Column(
                  children: [
                    /*TextFormField(
                      controller: viewModel.usernameController,
                      decoration: InputDecoration(labelText: 'Nom utilisateur'),
                      validator: (value) => value!.isEmpty ? 'Enter le nouveau nom utilisateur' : null,
                    ),*/
                    MyTextField(controller: viewModel.usernameController,
                        hintText: 'Nom utilisateur',
                        borderColor: Color(0xFF256C98),
                        borderWidth: 2.0
                    ),
                    MyTextField(controller: viewModel.emailController,
                        hintText: 'Email',
                        borderColor: Color(0xFF256C98),
                        borderWidth: 2.0
                    )
                    /*TextFormField(
                      controller: viewModel.emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (value) => value!.isEmpty ? 'Enter le nouveau email' : null,
                    )*/,
                    /*TextFormField(
                      controller: viewModel.passwordController,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe (Optional)',
                        suffixIcon: IconButton(
                          icon: Icon(
                            viewModel.isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Color(0xFF256C98),
                          ),
                          onPressed: () {
                            viewModel.togglePasswordVisibility();
                          },
                        ),
                      ),
                      obscureText: !viewModel.isPasswordVisible,
                    )*/
                    MyTextField(controller: viewModel.passwordController,
                      hintText: 'Password (Optionel)',
                      isPassword: true,
                      borderColor: Color(0xFF256C98),
                      borderWidth: 2.0,

                    )
                    ,
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF256C98),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () => viewModel.updateProfile(context, onUpdate),
                      child: Text('Sauvegarder'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

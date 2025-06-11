import 'package:emkamed_1/settings/profile_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Profile", style: TextStyle(color: Colors.white)),
              backgroundColor: Color(0xFF256C98),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ListTile(title: Text('Nom utilisateur'), subtitle: Text(viewModel.username)),
                ListTile(title: Text('Email'), subtitle: Text(viewModel.email)),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Editer Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF256C98),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        currentUsername: viewModel.username,
                        currentEmail: viewModel.email,
                        currentPassword: viewModel.password,
                        onUpdate: (newUsername, newEmail, newPassword) {
                          viewModel.updateProfile(newUsername, newEmail, newPassword);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

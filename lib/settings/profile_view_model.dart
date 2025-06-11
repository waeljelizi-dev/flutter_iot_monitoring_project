import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ProfileViewModel extends ChangeNotifier {
  String _username = "User";
  String _email = "user@example.com";
  String _password = "********";

  String get username => _username;
  String get email => _email;
  String get password => _password;

  ProfileViewModel() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    var box = await Hive.openBox('userBox');
    _username = box.get('username', defaultValue: "User");
    _email = box.get('email', defaultValue: "user@example.com");
    _password = box.get('password', defaultValue: "********");
    notifyListeners();
  }

  Future<void> updateProfile(String newUsername, String newEmail, String newPassword) async {
    var box = await Hive.openBox('userBox');
    await box.put('username', newUsername);
    await box.put('email', newEmail);
    await box.put('password', newPassword);

    _username = newUsername;
    _email = newEmail;
    _password = newPassword;
    notifyListeners();
  }
}

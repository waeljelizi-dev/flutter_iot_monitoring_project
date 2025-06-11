import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/device_model.dart';
import '../utils/ip_config.dart';

class UserRepository {
  final _userBoxName = 'userBox';
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse("http://${IpConfig.IP_ADDR}:8000/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"username": username, "password": password}),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Temps de connexion dépassé. Veuillez réessayer."};
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String password, String email) async {
    final String apiUrl = "http://${IpConfig.IP_ADDR}:8000/register";

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": username,
              "password": password,
              "email": email,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else if (response.statusCode == 400 || response.statusCode == 500) {
        return {"error": responseData["error"] ?? "Une erreur est survenue"};
      } else {
        return {"error": "Erreur inconnue, veuillez réessayer."};
      }
    } catch (e) {
      return {"error": "Temps de connexion dépassé ou erreur de réseau."};
    }
  }

  Future<void> saveUserAndDevice(User user, Device? device) async {
    final userBox = await Hive.openBox(_userBoxName);
    await userBox.put('userId', user.id);
    await userBox.put('username', user.username);
    await userBox.put('password', user.password);
    await userBox.put('email', user.email);

    if (device != null) {
      await userBox.put('deviceId', device.id);
      await userBox.put('adresse_mac', device.macAddress);
      await userBox.put('adresse_ip', device.ipAddress);
      await userBox.put('linked', device.linked);
    } else {
      await userBox.put('linked', false);
    }
  }

  Future<void> saveBasicInfo(String username, String email) async {
    final userBox = await Hive.openBox(_userBoxName);
    await userBox.put('username', username);
    await userBox.put('email', email);
  }

  Future<http.Response> sendResetPasswordEmail(String email) async {
    final response = await http.post(
      Uri.parse('http://${IpConfig.IP_ADDR}:8000/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return response;
  }

  Future<http.Response> verifyCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('http://${IpConfig.IP_ADDR}:8000/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    return response;
  }

  Future<http.Response> resetPassword(String email, String newPassword) async {
    final response = await http.post(
      Uri.parse('http://${IpConfig.IP_ADDR}:8000/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'newPassword': newPassword}),
    );
    return response;
  }

  Future<http.Response> updateProfile({
    required int userId,
    required String username,
    required String email,
    String? password,
  }) async {
    final response = await http.put(
      Uri.parse("http://${IpConfig.IP_ADDR}:8000/update-profile/$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );
    return response;
  }
}

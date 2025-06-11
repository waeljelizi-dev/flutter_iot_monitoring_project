import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stats_data.dart';
import '../models/eval_data.dart';
import '../utils/ip_config.dart';

class StatisticsRepository {
  // Define a constant for timeout duration
  static const Duration _requestTimeout = Duration(seconds: 10);

  Future<List<StatsData>> fetchStats(int deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('http://${IpConfig.IP_ADDR}:8000/stats/$deviceId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((json) => StatsData.fromJson(json)).toList();
      } else {
        throw Exception('Erreur ${response.statusCode}: Impossible de récupérer les données.');
      }
    } on http.ClientException {
      throw Exception('Erreur de connexion au serveur.');
    } on TimeoutException {
      throw Exception('Délai d\'attente dépassé. Veuillez réessayer.');
    }
  }

  Future<EvalData> fetchEvalData(int deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('http://${IpConfig.IP_ADDR}:8000/eval/$deviceId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EvalData.fromJson(data);
      } else {
        throw Exception('Erreur ${response.statusCode}: Impossible de récupérer les prédictions IA.');
      }
    } on http.ClientException {
      throw Exception('Erreur de connexion au serveur.');
    } on TimeoutException {
      throw Exception('Délai d\'attente dépassé. Veuillez réessayer.');
    }
  }
}
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/stats_data.dart';
import '../models/eval_data.dart';
import '../repository/statistics_repository.dart';

class StatisticsViewModel extends ChangeNotifier {
  final StatisticsRepository _repository;

  List<StatsData> _stats = [];
  EvalData? _evalData;
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastDisplayedError;
  bool _errorShown = false;
  bool _isNetworkError = false;
  bool _isTimeoutError = false;

  List<StatsData> get stats => _stats;
  EvalData? get evalData => _evalData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get errorShown => _errorShown;
  bool get isNetworkError => _isNetworkError;
  bool get isTimeoutError => _isTimeoutError;

  StatisticsViewModel(this._repository) {
    fetchAll();
  }

  Future<void> fetchAll() async {
    _isLoading = true;
    _errorMessage = null;
    _errorShown = false;
    _isNetworkError = false;
    _isTimeoutError = false;
    notifyListeners();

    final box = Hive.box('userBox');
    final int? deviceId = box.get('deviceId');

    if (deviceId == null) {
      _errorMessage = 'Aucun appareil lié.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _stats = await _repository.fetchStats(deviceId);
      _evalData = await _repository.fetchEvalData(deviceId);

      if (_stats.isEmpty) {
        _errorMessage = 'Aucune donnée disponible.';
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('Délai d\'attente dépassé')) {
        _isTimeoutError = true;
        _errorMessage = 'Délai d\'attente dépassé. Veuillez réessayer.';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable') ||
          e.toString().contains('Connection timed out') ||
          e.toString().contains('HttpException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Erreur de connexion au serveur')) {
        _isNetworkError = true;
        _errorMessage = 'Pas de connexion au serveur.';
      } else {
        _errorMessage = 'Problème de connexion au serveur.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    _lastDisplayedError = null;
    _isNetworkError = false;
    _isTimeoutError = false;
    notifyListeners();
  }

  void markErrorAsShown() {
    _errorShown = true;
    _lastDisplayedError = _errorMessage;
    notifyListeners();
  }

  bool shouldShowErrorSnackbar() {
    return _errorMessage != null && _errorMessage != _lastDisplayedError;
  }
}

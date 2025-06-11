import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/stats_data.dart';
import '../models/eval_data.dart';
import '../repository/statistics_repository.dart';
import './statistics_view_model.dart';
import '../widgets/round_snackbar.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  Timer? _refreshTimer;
  DateTime _lastRefreshTime = DateTime.now();
  late final StatisticsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StatisticsViewModel(StatisticsRepository());
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      debugPrint("Timer triggered refresh at ${DateTime.now()}");
      Future.microtask(() => _loadData());
    });
  }

  Future<void> _loadData() async {
    debugPrint("Starting _loadData() at ${DateTime.now()}");
    try {
      await _viewModel.fetchAll();
      if (mounted) {
        setState(() {
          _lastRefreshTime = DateTime.now();
          debugPrint("UI updated at $_lastRefreshTime");
        });
      }
    } catch (e) {
      debugPrint("Error in _loadData(): $e");
      if (mounted) {
        setState(() {
          _lastRefreshTime = DateTime.now();
          debugPrint("UI updated after error at $_lastRefreshTime");
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistique", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF256C98),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _viewModel.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () => _loadData(),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadData();
            if (_viewModel.shouldShowErrorSnackbar()) {
              if (_viewModel.isNetworkError || _viewModel.isTimeoutError) {
                RoundSnackBar.show(context, _viewModel.errorMessage!,
                    color: Colors.red);
              } else if (_viewModel.stats.isEmpty) {
                RoundSnackBar.show(context, _viewModel.errorMessage!,
                    color: Colors.orange);
              }
              _viewModel.markErrorAsShown();
            }
          },
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_viewModel.shouldShowErrorSnackbar()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RoundSnackBar.show(context, _viewModel.errorMessage!,
            color: Colors.red);
        _viewModel.markErrorAsShown();
      });
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_viewModel.isNetworkError || _viewModel.isTimeoutError)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.signal_wifi_off, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Pas de connexion au serveur. Tirez vers le bas pour rafraîchir.",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          _buildLayout(),
        ],
      ),
    );
  }

  Widget _buildLayout() {
    final data = _viewModel.stats.isNotEmpty ? _viewModel.stats[0] : null;
    final evalData = _viewModel.evalData ??
        EvalData(
          isPerformant: false,
          avgTemperature: 0,
          avgVoltage: 0,
          avgCurrent: 0,
          avgPower: 0,
          advices: [],
        );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard("Voltage", "assets/icons/voltage.svg",
                data?.avgVoltage, "V", Colors.orange),
            _buildStatCard("Température", "assets/icons/temperature.svg",
                data?.avgTemperature, "°C", Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard("Courant", "assets/icons/current.svg",
                data?.avgCurrent, "A", Colors.blue),
            _buildStatCard("Puissance", "assets/icons/power_battery.svg",
                data?.avgPower, "W", Colors.green),
          ],
        ),
        const SizedBox(height: 20),
        _buildBarChart(_viewModel.stats),
        const SizedBox(height: 20),
        _buildModernEvaluations(evalData),
        const SizedBox(height: 20),
        _buildAdvices(evalData.advices),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String iconPath, double? value, String unit, Color color) {
    final displayValue =
        value != null ? "${value.toStringAsFixed(1)}$unit" : "-- $unit";

    return Container(
      width: 160,
      height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 32,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Text(
                displayValue,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<StatsData> stats) {
    final allData = List<StatsData>.generate(10, (index) {
      if (index < stats.length) {
        return stats[index];
      } else {
        return StatsData(
          date: DateTime.now()
              .subtract(Duration(minutes: 9 - index))
              .toIso8601String()
              .substring(11, 16),
          avgVoltage: 0,
          avgCurrent: 0,
          avgTemperature: 0,
          avgPower: 0,
        );
      }
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Consommation d'énergie (10 dernières minutes)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: stats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart,
                              size: 64, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            "Aucune donnée disponible",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : SfCartesianChart(
                      primaryXAxis: CategoryAxis(
                          labelStyle: const TextStyle(fontSize: 10)),
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: 10,
                        interval: 5,
                        labelStyle: const TextStyle(fontSize: 8),
                      ),
                      series: <ChartSeries>[
                        ColumnSeries<StatsData, String>(
                          dataSource: allData,
                          xValueMapper: (data, index) => index < stats.length
                              ? data.date.substring(11, 16)
                              : "${9 - index} min",
                          yValueMapper: (data, _) => data.avgPower,
                          color: const Color(0xFF256C98),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4)),
                          spacing: 0.2,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEvaluations(EvalData? evalData) {
    final hasData = evalData != null &&
        (evalData.avgVoltage != 0 ||
            evalData.avgCurrent != 0 ||
            evalData.avgTemperature != 0 ||
            evalData.avgPower != 0);

    if (!hasData) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "📊 Évaluations",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  "Aucune données",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📊 Évaluations",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildModernEvaluationCard(
              "Tension",
              "${evalData!.avgVoltage.toStringAsFixed(1)}V",
              Icons.bolt,
              Colors.orange,
            ),
            _buildModernEvaluationCard(
              "Courant",
              "${evalData.avgCurrent.toStringAsFixed(1)}A",
              Icons.electric_bolt,
              Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildModernEvaluationCard(
              "Température",
              "${evalData.avgTemperature.toStringAsFixed(1)}°C",
              Icons.thermostat,
              Colors.red,
            ),
            _buildModernEvaluationCard(
              "Puissance",
              "${evalData.avgPower.toStringAsFixed(1)}W",
              Icons.battery_6_bar_sharp,
              Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildModernEvaluationCard(
          "Performance",
          evalData.isPerformant ? "Performant" : "Non performant",
          Icons.check_circle,
          evalData.isPerformant ? Colors.green : Colors.red,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildModernEvaluationCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  value,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvices(List<String> advices) {
    final splitAdvices = advices
        .expand((advice) =>
            advice.split('.').map((a) => a.trim()).where((a) => a.isNotEmpty))
        .toList();
    final hasAdvices = splitAdvices.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🧠 Conseils",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (hasAdvices)
              ...splitAdvices.map((advice) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("• ", style: TextStyle(fontSize: 14)),
                        Expanded(
                            child: Text(advice,
                                style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ))
            else
              const Text(
                "Aucun conseil disponible pour le moment",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

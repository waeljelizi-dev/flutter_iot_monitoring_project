import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart'; // Add this import for DateFormat

import '../models/live_data.dart';
import 'mqtt_view_model.dart';

class MqttScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MqttViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Row(
          children: [
            Text("Tableau de bord", style: TextStyle(color: Colors.white)),
            Spacer(),
          ],
        ),
        backgroundColor: Color(0xFF256C98),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Connection status card (only show if there's an error or connecting)
            if (!viewModel.isConnected || viewModel.errorMessage.isNotEmpty)
              _buildConnectionStatusCard(viewModel),
            if (!viewModel.isConnected || viewModel.errorMessage.isNotEmpty)
              const SizedBox(height: 16),
            _buildMainCard(viewModel),
            const SizedBox(height: 16),
            _buildPowerCard(viewModel),
            const SizedBox(height: 16),
            _buildChart(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(MqttViewModel viewModel) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      //color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  viewModel.getStatusIcon(),
                  color: viewModel.getStatusColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'État de connexion: ${viewModel.connectionStatus}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: viewModel.getStatusColor(),
                        ),
                      ),
                      if (viewModel.errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          viewModel.errorMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: viewModel.getStatusColor(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (viewModel.isConnecting)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          viewModel.getStatusColor()),
                    ),
                  ),
              ],
            ),
            if (!viewModel.isConnected && !viewModel.isConnecting) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => viewModel.reconnect(),
                  icon: Icon(Icons.refresh),
                  label: Text('Reconnecter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: viewModel.getStatusColor(),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(MqttViewModel viewModel) {
    final opacity = viewModel.isConnected ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildValueColumn("Tension", viewModel.voltage.toString(),
                      " V", Colors.orange),
                  _buildValueColumn("Courant", viewModel.current.toString(),
                      " A", Colors.blue),
                  _buildValueColumn("Temp", viewModel.temperature.toString(),
                      "°C", Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForMetric(String metric) {
    switch (metric) {
      case "Tension":
        return Icons.bolt;
      case "Courant":
        return Icons.electric_meter;
      case "Temp":
        return Icons.thermostat;
      default:
        return Icons.show_chart;
    }
  }

  Widget _buildValueColumn(
      String label, String value, String suffix, Color iconColor) {
    return Column(
      children: [
        Icon(
          _getIconForMetric(label),
          size: 40,
          color: iconColor,
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black54)),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        Text(suffix,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black54)),
      ],
    );
  }

  Widget _buildPowerCard(MqttViewModel viewModel) {
    final opacity = viewModel.isConnected ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.green,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text("Consommation d'énergie",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text("${viewModel.power.toStringAsFixed(2)} W",
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(MqttViewModel viewModel) {
    if (viewModel.chartData.isEmpty) {
      String message;
      if (viewModel.isConnecting) {
        message = "Connexion en cours...";
      } else if (!viewModel.isConnected) {
        message =
            "Pas de connexion MQTT\nVérifiez l'adresse IP et la connectivité réseau";
      } else {
        message = "En attente de données...";
      }

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  viewModel.getStatusIcon(),
                  size: 48,
                  color: viewModel.getStatusColor(),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (viewModel.isConnecting) ...[
                  const SizedBox(height: 16),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        viewModel.getStatusColor()),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 300,
          child: SfCartesianChart(
            primaryXAxis: DateTimeAxis(
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              dateFormat: DateFormat.Hms(), // Show only hours:minutes:seconds
              intervalType: DateTimeIntervalType.auto,
              majorGridLines: const MajorGridLines(width: 0),
            ),
            primaryYAxis: NumericAxis(
              labelFormat: '{value}',
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
            ),
            legend: Legend(isVisible: true, position: LegendPosition.bottom),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <CartesianSeries<LiveData, DateTime>>[
              LineSeries<LiveData, DateTime>(
                dataSource: viewModel.chartData,
                xValueMapper: (LiveData data, _) => data.time,
                yValueMapper: (LiveData data, _) => data.voltage,
                color: Colors.orange,
                name: "Tension",
                markerSettings: const MarkerSettings(isVisible: true),
              ),
              LineSeries<LiveData, DateTime>(
                dataSource: viewModel.chartData,
                xValueMapper: (LiveData data, _) => data.time,
                yValueMapper: (LiveData data, _) => data.current,
                color: Colors.blue,
                name: "Courant",
                markerSettings: const MarkerSettings(isVisible: true),
              ),
              LineSeries<LiveData, DateTime>(
                dataSource: viewModel.chartData,
                xValueMapper: (LiveData data, _) => data.time,
                yValueMapper: (LiveData data, _) => data.temperature,
                color: Colors.red,
                name: "Temperature",
                markerSettings: const MarkerSettings(isVisible: true),
              ),
              LineSeries<LiveData, DateTime>(
                dataSource: viewModel.chartData,
                xValueMapper: (LiveData data, _) => data.time,
                yValueMapper: (LiveData data, _) => data.power,
                color: Colors.green,
                name: "Puissance",
                markerSettings: const MarkerSettings(isVisible: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

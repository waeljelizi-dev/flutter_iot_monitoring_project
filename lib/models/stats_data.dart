class StatsData {
  final String date;
  final double avgVoltage;
  final double avgCurrent;
  final double avgTemperature;
  final double avgPower;

  StatsData({
    required this.date,
    required this.avgVoltage,
    required this.avgCurrent,
    required this.avgTemperature,
    required this.avgPower,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) {
    return StatsData(
      date: json['timestamp'],
      avgVoltage: json['avg_voltage']?.toDouble() ?? 0.0,
      avgCurrent: json['avg_current']?.toDouble() ?? 0.0,
      avgTemperature: json['avg_temperature']?.toDouble() ?? 0.0,
      avgPower: json['avg_power']?.toDouble() ?? 0.0,
    );
  }
}

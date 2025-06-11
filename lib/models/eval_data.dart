class EvalData {
  final bool isPerformant;
  final double avgTemperature;
  final double avgVoltage;
  final double avgCurrent;
  final double avgPower;
  final List<String> advices;

  EvalData({
    required this.isPerformant,
    required this.avgTemperature,
    required this.avgVoltage,
    required this.avgCurrent,
    required this.avgPower,
    required this.advices,
  });

  factory EvalData.fromJson(Map<String, dynamic> json) {
    final prediction = json['prediction'] ?? {};
    final advicesList =
        (json['advices'] as List<dynamic>).map((e) => e.toString()).toList();

    return EvalData(
      isPerformant: prediction['is_performant'] == 1,
      avgTemperature: (prediction['avg_temperature'] ?? 0).toDouble(),
      avgVoltage: (prediction['avg_voltage'] ?? 0).toDouble(),
      avgCurrent: (prediction['avg_current'] ?? 0).toDouble(),
      avgPower: (prediction['avg_power'] ?? 0).toDouble(),
      advices: advicesList,
    );
  }
}

class MqttMessage {
  final double voltage;
  final double current;
  final double temperature;

  MqttMessage(
      {required this.voltage,
      required this.current,
      required this.temperature});

  factory MqttMessage.fromJson(Map<String, dynamic> json) {
    return MqttMessage(
      voltage: double.tryParse(json['voltage'].toString()) ?? 0.0,
      current: double.tryParse(json['current'].toString()) ?? 0.0,
      temperature: double.tryParse(json['temperature'].toString()) ?? 0.0,
    );
  }
}

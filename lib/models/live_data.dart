class LiveData {
  final DateTime time;
  final double voltage;
  final double current;
  final double temperature;
  final double power;

  LiveData(this.time, this.voltage, this.current, this.temperature, this.power);

  factory LiveData.now(
      double voltage, double current, double temperature, double power) {
    return LiveData(DateTime.now(), voltage, current, temperature, power);
  }
}

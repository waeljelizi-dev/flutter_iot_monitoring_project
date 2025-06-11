class Device {
  final int id;
  final String macAddress;
  final String ipAddress;
  final bool linked;
  final int userId;

  Device({
    required this.id,
    required this.macAddress,
    required this.ipAddress,
    required this.linked,
    required this.userId,
  });
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? json['device_id'] ?? -1,
      macAddress: json['adresse_mac'] ?? '',
      ipAddress: json['adresse_ip'] ?? '',
      linked: json['linked'] == 1 || json['linked'] == true, // Convert to bool
      userId: json['user_id'] ?? -1,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adresse_mac': macAddress,
      'adresse_ip': ipAddress,
      'linked': linked ? 1 : 0,
      'user_id': userId,
    };
  }
}

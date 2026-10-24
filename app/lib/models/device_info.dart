import 'dart:convert';

class DeviceInfo {
  const DeviceInfo({
    required this.firmware,
    required this.rssi,
    required this.uptime,
    required this.ip,
    this.lastSeen,
  });

  final String firmware;
  final int rssi;
  final Duration uptime;
  final String ip;

  final DateTime? lastSeen;

  static DeviceInfo? tryParse(String payload) {
    final Object? data;
    try {
      data = jsonDecode(payload);
    } on FormatException {
      return null;
    }

    if (data case {
      'firmware': String firmware,
      'rssi': int rssi,
      'uptime': int uptime,
      'ip': String ip,
      'time': int time,
    }) {
      return DeviceInfo(
        firmware: firmware,
        rssi: rssi,
        uptime: Duration(seconds: uptime),
        ip: ip,
        lastSeen: time > 0
            ? DateTime.fromMillisecondsSinceEpoch(time * 1000)
            : null,
      );
    }
    return null;
  }
}

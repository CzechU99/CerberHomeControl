import 'package:flutter/material.dart';

import '../models/device_info.dart';
import '../models/gate.dart';
import '../utils/device_info_format.dart';

class StatusPage extends StatelessWidget {
  const StatusPage({
    super.key,
    required this.isBrokerConnected,
    required this.gateOnline,
    required this.deviceInfo,
  });

  final bool isBrokerConnected;
  final Map<String, bool> gateOnline;
  final Map<String, DeviceInfo> deviceInfo;

  Widget _buildStatusRow(String label, bool isOnline) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 20)),
        Icon(
          isOnline ? Icons.wifi : Icons.wifi_off,
          color: isOnline ? Colors.green : Colors.red,
          size: 30,
        ),
      ],
    );
  }

  List<String> _detailLines(DeviceInfo info, {required bool isOnline}) {
    final lastSeen = info.lastSeen;
    return [
      if (isOnline) ...[
        'Firmware ${info.firmware} · IP ${info.ip}',
        'Wi-Fi ${info.rssi} dBm (${signalQuality(info.rssi)}) · '
            'działa ${formatUptime(info.uptime)}',
      ] else
        'Firmware ${info.firmware}',
      if (lastSeen != null)
        'Widziany: ${formatLastSeen(lastSeen, now: DateTime.now())}',
    ];
  }

  Widget _buildGateSection(Gate gate) {
    final isOnline = gateOnline[gate.id] ?? false;
    final info = deviceInfo[gate.id];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          _buildStatusRow(gate.statusLabel, isOnline),
          if (info != null)
            for (final line in _detailLines(info, isOnline: isOnline))
              Text(
                line,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: _buildStatusRow('Połączenie broker', isBrokerConnected),
        ),
        for (final gate in gates) ...[
          const Divider(color: Colors.white, thickness: 1),
          _buildGateSection(gate),
        ],
      ],
    );
  }
}

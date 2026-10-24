import 'package:flutter/material.dart';

import '../models/gate.dart';

class StatusPage extends StatelessWidget {
  const StatusPage({
    super.key,
    required this.isBrokerConnected,
    required this.gateOnline,
  });

  final bool isBrokerConnected;
  final Map<String, bool> gateOnline;

  Widget _buildStatusRow(String label, bool isOnline) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 20)),
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: isOnline ? Colors.green : Colors.red,
            size: 30,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStatusRow('Połączenie broker', isBrokerConnected),
          for (final gate in gates) ...[
            const Divider(color: Colors.white, thickness: 1),
            _buildStatusRow(gate.statusLabel, gateOnline[gate.id] ?? false),
          ],
        ],
      ),
    );
  }
}

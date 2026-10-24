import 'package:flutter/material.dart';

import '../models/gate.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.sendCommand,
    required this.isBrokerConnected,
    required this.gateOnline,
  });

  final void Function(String topic, String message) sendCommand;
  final bool isBrokerConnected;
  final Map<String, bool> gateOnline;

  Widget _buildGateButton(Gate gate) {
    final isAvailable = isBrokerConnected && (gateOnline[gate.id] ?? false);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      onPressed: isAvailable
          ? () => sendCommand(gate.commandTopic, gateStartCommand)
          : null,
      child: Text(
        gate.buttonLabel,
        style: const TextStyle(
          fontSize: 25,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        spacing: 20,
        children: [for (final gate in gates) _buildGateButton(gate)],
      ),
    );
  }
}

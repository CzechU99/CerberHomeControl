import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/gate.dart';
import '../services/command_tracker.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onOpenGate,
    required this.isBrokerConnected,
    required this.gateOnline,
    required this.commandStatuses,
  });

  final void Function(Gate gate) onOpenGate;
  final bool isBrokerConnected;
  final Map<String, bool> gateOnline;
  final Map<String, CommandStatus> commandStatuses;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        spacing: 20,
        children: [
          for (final gate in gates)
            _GateButton(
              gate: gate,
              isAvailable: isBrokerConnected && (gateOnline[gate.id] ?? false),
              commandStatus: commandStatuses[gate.id] ?? CommandStatus.idle,
              onOpen: () => onOpenGate(gate),
            ),
        ],
      ),
    );
  }
}

class _GateButton extends StatefulWidget {
  const _GateButton({
    required this.gate,
    required this.isAvailable,
    required this.commandStatus,
    required this.onOpen,
  });

  final Gate gate;
  final bool isAvailable;
  final CommandStatus commandStatus;
  final VoidCallback onOpen;

  @override
  State<_GateButton> createState() => _GateButtonState();
}

class _GateButtonState extends State<_GateButton> {
  @override
  void didUpdateWidget(_GateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commandStatus == widget.commandStatus) return;

    switch (widget.commandStatus) {
      case CommandStatus.confirmed:
        HapticFeedback.mediumImpact();
      case CommandStatus.failed:
        HapticFeedback.heavyImpact();
      case CommandStatus.idle || CommandStatus.pending:
        break;
    }
  }

  Widget? _buildStatusIcon() {
    return switch (widget.commandStatus) {
      CommandStatus.pending => const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
      ),
      CommandStatus.confirmed => const Icon(
        Icons.check_circle,
        color: Colors.greenAccent,
        size: 28,
      ),
      CommandStatus.failed => const Icon(
        Icons.error,
        color: Colors.orangeAccent,
        size: 28,
      ),
      CommandStatus.idle => null,
    };
  }

  void _showHoldHint() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Przytrzymaj przycisk, aby otworzyć bramę'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled =
        widget.isAvailable && widget.commandStatus != CommandStatus.pending;
    final statusIcon = _buildStatusIcon();

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      onPressed: isEnabled ? _showHoldHint : null,
      onLongPress: isEnabled ? widget.onOpen : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          Text(
            widget.gate.buttonLabel,
            style: const TextStyle(
              fontSize: 25,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          ?statusIcon,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/gate.dart';
import '../services/command_tracker.dart';
import '../services/haptics.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.gates,
    required this.onOpenGate,
    required this.isBrokerConnected,
    required this.gateOnline,
    required this.commandStatuses,
    required this.holdDuration,
    required this.vibrationEnabled,
  });

  final List<Gate> gates;
  final void Function(Gate gate) onOpenGate;
  final bool isBrokerConnected;
  final Map<String, bool> gateOnline;
  final Map<String, CommandStatus> commandStatuses;
  final Duration holdDuration;
  final bool vibrationEnabled;

  @override
  Widget build(BuildContext context) {
    if (gates.isEmpty) {
      return const Center(
        child: Text(
          'Wszystkie bramy są ukryte.\nWłącz je w Ustawienia → Ogólne.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        spacing: 20,
        children: [
          for (final gate in gates)
            _GateButton(
              key: ValueKey(gate.id),
              gate: gate,
              isAvailable: isBrokerConnected && (gateOnline[gate.id] ?? false),
              commandStatus: commandStatuses[gate.id] ?? CommandStatus.idle,
              holdDuration: holdDuration,
              vibrationEnabled: vibrationEnabled,
              onOpen: () => onOpenGate(gate),
            ),
        ],
      ),
    );
  }
}

class _GateButton extends StatefulWidget {
  const _GateButton({
    super.key,
    required this.gate,
    required this.isAvailable,
    required this.commandStatus,
    required this.holdDuration,
    required this.vibrationEnabled,
    required this.onOpen,
  });

  final Gate gate;
  final bool isAvailable;
  final CommandStatus commandStatus;
  final Duration holdDuration;
  final bool vibrationEnabled;
  final VoidCallback onOpen;

  @override
  State<_GateButton> createState() => _GateButtonState();
}

class _GateButtonState extends State<_GateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  )..addStatusListener(_onHoldStatus);

  bool get _isEnabled =>
      widget.isAvailable && widget.commandStatus != CommandStatus.pending;

  @override
  void didUpdateWidget(_GateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hold.duration = widget.holdDuration;
    if (!_isEnabled) _hold.reset();

    if (oldWidget.commandStatus == widget.commandStatus ||
        !widget.vibrationEnabled) {
      return;
    }
    switch (widget.commandStatus) {
      case CommandStatus.confirmed:
        Haptics.commandConfirmed();
      case CommandStatus.failed:
        Haptics.commandFailed();
      case CommandStatus.idle || CommandStatus.pending:
        break;
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    if (widget.vibrationEnabled) Haptics.gateOpening();
    widget.onOpen();
    _hold.reset();
  }

  void _startHold() {
    if (_isEnabled) _hold.forward(from: 0);
  }

  void _endHold() {
    if (!_hold.isAnimating) return;

    _hold.reset();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Przytrzymaj przycisk, aby otworzyć bramę'),
          duration: Duration(seconds: 2),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final isEnabled = _isEnabled;
    final statusIcon = _buildStatusIcon();

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.gate.buttonLabel,
      hint: 'Przytrzymaj, aby otworzyć',
      child: Listener(
        onPointerDown: (_) => _startHold(),
        onPointerUp: (_) => _endHold(),
        onPointerCancel: (_) => _endHold(),
        child: Material(
          color: isEnabled ? Colors.blue : Colors.white12,
          borderRadius: BorderRadius.circular(5),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 60,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _hold,
                  builder: (context, _) => FractionallySizedBox(
                    widthFactor: _hold.value,
                    heightFactor: 1,
                    child: const ColoredBox(color: Colors.lightBlueAccent),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12,
                    children: [
                      Text(
                        widget.gate.buttonLabel,
                        style: TextStyle(
                          fontSize: 25,
                          color: isEnabled ? Colors.white : Colors.white38,
                          letterSpacing: 1,
                        ),
                      ),
                      ?statusIcon,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

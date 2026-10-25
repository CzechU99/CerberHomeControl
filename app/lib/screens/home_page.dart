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
    with TickerProviderStateMixin {
  static const _flashDuration = Duration(milliseconds: 900);

  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  )..addStatusListener(_onHoldStatus);

  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: _flashDuration,
  );
  late final Animation<double> _flashOpacity = TweenSequence([
    for (var i = 0; i < 2; i++) ...[
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
    ],
  ]).animate(_flash);
  Color _flashColor = Colors.green;

  bool get _isPending => widget.commandStatus == CommandStatus.pending;
  bool get _canHold => widget.isAvailable && !_isPending;

  @override
  void didUpdateWidget(_GateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hold.duration = widget.holdDuration;
    if (!_canHold) _hold.reset();

    if (oldWidget.commandStatus == widget.commandStatus) return;
    switch (widget.commandStatus) {
      case CommandStatus.confirmed:
        _showResult(Colors.green);
        if (widget.vibrationEnabled) Haptics.commandConfirmed();
      case CommandStatus.failed:
        _showResult(Colors.red);
        if (widget.vibrationEnabled) Haptics.commandFailed();
      case CommandStatus.idle || CommandStatus.pending:
        break;
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    _flash.dispose();
    super.dispose();
  }

  void _showResult(Color color) {
    _flashColor = color;
    _flash.forward(from: 0);
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    if (widget.vibrationEnabled) Haptics.gateOpening();
    widget.onOpen();
    _hold.reset();
  }

  void _startHold() {
    if (_canHold) _hold.forward(from: 0);
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

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.isAvailable;

    return Semantics(
      button: true,
      enabled: _canHold,
      label: widget.gate.buttonLabel,
      hint: 'Przytrzymaj, aby otworzyć',
      child: Listener(
        onPointerDown: (_) => _startHold(),
        onPointerUp: (_) => _endHold(),
        onPointerCancel: (_) => _endHold(),
        child: Material(
          color: isAvailable ? Colors.blue : Colors.white12,
          borderRadius: BorderRadius.circular(5),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedBuilder(
                    animation: _hold,
                    builder: (context, _) => FractionallySizedBox(
                      widthFactor: _isPending ? 1 : _hold.value,
                      heightFactor: 1,
                      child: const ColoredBox(color: Colors.lightBlueAccent),
                    ),
                  ),
                ),
                FadeTransition(
                  key: const ValueKey('gate-button-flash'),
                  opacity: _flashOpacity,
                  child: ColoredBox(color: _flashColor),
                ),
                Center(
                  child: Text(
                    widget.gate.buttonLabel,
                    style: TextStyle(
                      fontSize: 25,
                      color: isAvailable ? Colors.white : Colors.white38,
                      letterSpacing: 1,
                    ),
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

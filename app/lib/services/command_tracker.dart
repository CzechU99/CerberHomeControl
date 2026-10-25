import 'dart:async';

import 'package:flutter/foundation.dart';

enum CommandStatus { idle, pending, confirmed, failed }

class CommandTracker {
  CommandTracker({
    required this.onChanged,
    this.ackTimeout = const Duration(seconds: 5),
    this.resultDuration = const Duration(seconds: 3),
  });

  final VoidCallback onChanged;
  final Duration resultDuration;

  Duration ackTimeout;

  final Map<String, CommandStatus> _statuses = {};
  final Map<String, Timer> _timers = {};

  CommandStatus statusOf(String gateId) =>
      _statuses[gateId] ?? CommandStatus.idle;

  void start(String gateId) => _setStatus(gateId, CommandStatus.pending);

  void acknowledge(String gateId, {required bool accepted}) {
    if (statusOf(gateId) != CommandStatus.pending) return;
    _setStatus(
      gateId,
      accepted ? CommandStatus.confirmed : CommandStatus.failed,
    );
  }

  void _setStatus(String gateId, CommandStatus status) {
    _timers.remove(gateId)?.cancel();
    _statuses[gateId] = status;
    onChanged();

    final next = switch (status) {
      CommandStatus.pending => (ackTimeout, CommandStatus.failed),
      CommandStatus.confirmed ||
      CommandStatus.failed => (resultDuration, CommandStatus.idle),
      CommandStatus.idle => null,
    };
    if (next == null) return;

    final (delay, nextStatus) = next;
    _timers[gateId] = Timer(delay, () => _setStatus(gateId, nextStatus));
  }

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}

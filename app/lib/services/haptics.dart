import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class Haptics {
  const Haptics._();

  static void gateOpening() => _vibrate(duration: 60);
  static void commandConfirmed() => _vibrate(duration: 150);
  static void commandFailed() => _vibrate(pattern: const [0, 150, 120, 150]);

  static Future<void> _vibrate({
    int duration = 0,
    List<int> pattern = const [],
  }) async {
    try {
      await Vibration.vibrate(duration: duration, pattern: pattern);
    } catch (e) {
      debugPrint('Vibration unavailable: $e');
    }
  }
}

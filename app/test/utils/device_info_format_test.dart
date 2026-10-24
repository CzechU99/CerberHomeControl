import 'package:cerber/utils/device_info_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats uptime', () {
    expect(formatUptime(const Duration(minutes: 5)), '5 min');
    expect(formatUptime(const Duration(hours: 3, minutes: 12)), '3 h 12 min');
    expect(formatUptime(const Duration(days: 2, hours: 4)), '2 d 4 h');
  });

  test('formats last seen relative to now', () {
    final now = DateTime(2026, 10, 24, 12);

    expect(
      formatLastSeen(now.subtract(const Duration(seconds: 30)), now: now),
      'przed chwilą',
    );
    expect(
      formatLastSeen(now.subtract(const Duration(minutes: 5)), now: now),
      '5 min temu',
    );
    expect(
      formatLastSeen(now.subtract(const Duration(hours: 3)), now: now),
      '3 h temu',
    );
    expect(
      formatLastSeen(DateTime(2026, 10, 20, 8, 5), now: now),
      '20.10.2026 08:05',
    );
  });

  test('rates Wi-Fi signal strength', () {
    expect(signalQuality(-55), 'dobry');
    expect(signalQuality(-70), 'średni');
    expect(signalQuality(-85), 'słaby');
  });
}

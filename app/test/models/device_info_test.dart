import 'package:cerber/models/device_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the payload published by the ESP', () {
    final info = DeviceInfo.tryParse(
      '{"firmware":"1.2.0","rssi":-61,"uptime":3720,'
      '"ip":"192.168.1.50","time":1793000000}',
    );

    expect(info, isNotNull);
    expect(info!.firmware, '1.2.0');
    expect(info.rssi, -61);
    expect(info.uptime, const Duration(hours: 1, minutes: 2));
    expect(info.ip, '192.168.1.50');
    expect(
      info.lastSeen,
      DateTime.fromMillisecondsSinceEpoch(1793000000 * 1000),
    );
  });

  test('has no last seen time before NTP sync', () {
    final info = DeviceInfo.tryParse(
      '{"firmware":"1.2.0","rssi":-61,"uptime":10,"ip":"10.0.0.2","time":0}',
    );

    expect(info?.lastSeen, isNull);
  });

  test('rejects invalid payloads', () {
    expect(DeviceInfo.tryParse('not json'), isNull);
    expect(DeviceInfo.tryParse('{"firmware":"1.2.0"}'), isNull);
    expect(DeviceInfo.tryParse('[1, 2]'), isNull);
  });
}

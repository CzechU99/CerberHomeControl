import 'package:cerber/services/command_tracker.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gateId = 'honda';
  const ackTimeout = Duration(seconds: 5);
  const resultDuration = Duration(seconds: 3);

  CommandTracker createTracker() => CommandTracker(
    onChanged: () {},
    ackTimeout: ackTimeout,
    resultDuration: resultDuration,
  );

  test('is idle before any command', () {
    expect(createTracker().statusOf(gateId), CommandStatus.idle);
  });

  test('confirms an accepted ack and returns to idle', () {
    fakeAsync((async) {
      final tracker = createTracker()..start(gateId);
      expect(tracker.statusOf(gateId), CommandStatus.pending);

      tracker.acknowledge(gateId, accepted: true);
      expect(tracker.statusOf(gateId), CommandStatus.confirmed);

      async.elapse(resultDuration);
      expect(tracker.statusOf(gateId), CommandStatus.idle);
    });
  });

  test('fails on a rejected ack', () {
    final tracker = createTracker()..start(gateId);

    tracker.acknowledge(gateId, accepted: false);

    expect(tracker.statusOf(gateId), CommandStatus.failed);
    tracker.dispose();
  });

  test('fails when no ack arrives in time', () {
    fakeAsync((async) {
      final tracker = createTracker()..start(gateId);

      async.elapse(ackTimeout);
      expect(tracker.statusOf(gateId), CommandStatus.failed);

      async.elapse(resultDuration);
      expect(tracker.statusOf(gateId), CommandStatus.idle);
    });
  });

  test('ignores an ack without a pending command', () {
    final tracker = createTracker();

    tracker.acknowledge(gateId, accepted: true);

    expect(tracker.statusOf(gateId), CommandStatus.idle);
  });

  test('a late ack does not override a timeout', () {
    fakeAsync((async) {
      final tracker = createTracker()..start(gateId);

      async.elapse(ackTimeout);
      tracker.acknowledge(gateId, accepted: true);

      expect(tracker.statusOf(gateId), CommandStatus.failed);
      tracker.dispose();
    });
  });
}

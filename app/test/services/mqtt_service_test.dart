import 'package:cerber/models/gate.dart';
import 'package:cerber/services/mqtt_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttReceivedMessage<MqttMessage> statusMessage(Gate gate, String status) {
  final payload = MqttClientPayloadBuilder()..addString(status);
  final message = MqttPublishMessage()
      .toTopic(gate.statusTopic)
      .publishData(payload.payload!);
  return MqttReceivedMessage<MqttMessage>(gate.statusTopic, message);
}

void main() {
  late MqttService service;

  setUp(() => service = MqttService());
  tearDown(() => service.dispose());

  test('all gates start offline', () {
    expect(service.gateOnline.values, everyElement(isFalse));
  });

  test('applies every status from a batch of messages', () {
    service.handleMessages([
      for (final gate in gates) statusMessage(gate, deviceOnlineStatus),
    ]);

    expect(service.gateOnline.values, everyElement(isTrue));
  });

  test('marks a gate offline on any other status', () {
    final gate = gates.first;

    service.handleMessages([statusMessage(gate, deviceOnlineStatus)]);
    service.handleMessages([statusMessage(gate, 'OFFLINE')]);

    expect(service.gateOnline[gate.id], isFalse);
  });

  test('notifies listeners once per batch', () {
    var notifications = 0;
    service.addListener(() => notifications++);

    service.handleMessages([
      for (final gate in gates) statusMessage(gate, deviceOnlineStatus),
    ]);

    expect(notifications, 1);
  });
}

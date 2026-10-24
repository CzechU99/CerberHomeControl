import 'package:cerber/models/gate.dart';
import 'package:cerber/services/mqtt_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttReceivedMessage<MqttMessage> mqttMessage(String topic, String text) {
  final payload = MqttClientPayloadBuilder()..addString(text);
  final message = MqttPublishMessage()
      .toTopic(topic)
      .publishData(payload.payload!);
  return MqttReceivedMessage<MqttMessage>(topic, message);
}

MqttReceivedMessage<MqttMessage> statusMessage(Gate gate, String status) =>
    mqttMessage(gate.statusTopic, status);

void main() {
  late MqttService service;

  setUp(() => service = MqttService());
  tearDown(() => service.dispose());

  test('stores device info and ignores invalid payloads', () {
    final honda = gates.first;
    const payload =
        '{"firmware":"1.2.0","rssi":-61,"uptime":60,"ip":"10.0.0.2","time":0}';

    service.handleMessages([mqttMessage(honda.infoTopic, payload)]);
    service.handleMessages([mqttMessage(honda.infoTopic, 'garbage')]);

    expect(service.deviceInfo[honda.id]?.firmware, '1.2.0');
  });

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

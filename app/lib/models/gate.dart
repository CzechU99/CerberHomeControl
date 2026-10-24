const String gateStartCommand = 'START';
const String deviceOnlineStatus = 'ONLINE';
const String commandAcceptedAck = 'OK';
const String infoRequestMessage = 'GET';

class Gate {
  const Gate({
    required this.id,
    required this.buttonLabel,
    required this.statusLabel,
  });

  /// Device id used in MQTT topics, must match the firmware.
  final String id;
  final String buttonLabel;
  final String statusLabel;

  String get commandTopic => 'cerber/$id/command';
  String get statusTopic => 'cerber/$id/status';
  String get ackTopic => 'cerber/$id/ack';
  String get infoTopic => 'cerber/$id/info';
  String get infoRequestTopic => 'cerber/$id/info/request';
}

const List<Gate> gates = [
  Gate(id: 'honda', buttonLabel: 'BRAMA  HONDA', statusLabel: 'Garaż Honda'),
  Gate(
    id: 'hyundai',
    buttonLabel: 'BRAMA  HYUNDAI',
    statusLabel: 'Garaż Hyundai',
  ),
  Gate(
    id: 'toyota',
    buttonLabel: 'BRAMA  TOYOTA',
    statusLabel: 'Garaż stodoła',
  ),
  Gate(
    id: 'main_gate',
    buttonLabel: 'BRAMA  PODWÓRKO',
    statusLabel: 'Brama podwórko',
  ),
];

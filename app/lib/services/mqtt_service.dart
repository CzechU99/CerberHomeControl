import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../models/gate.dart';
import '../models/mqtt_settings.dart';
import 'command_tracker.dart';

class MqttService extends ChangeNotifier {
  static const _retryDelay = Duration(seconds: 10);

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updates;
  MqttSettings? _settings;
  Timer? _retryTimer;
  bool _hasConnected = false;
  bool _isPaused = false;

  bool _isBrokerConnected = false;
  final Map<String, bool> _gateOnline = {
    for (final gate in gates) gate.id: false,
  };
  late final _commands = CommandTracker(onChanged: notifyListeners);

  bool get isBrokerConnected => _isBrokerConnected;
  Map<String, bool> get gateOnline => Map.unmodifiable(_gateOnline);
  Map<String, CommandStatus> get commandStatuses => {
    for (final gate in gates) gate.id: _commands.statusOf(gate.id),
  };

  Future<void> connect(MqttSettings settings) async {
    _closeConnection();
    _settings = settings;
    if (!settings.isComplete) return;

    final client =
        MqttServerClient.withPort(
            settings.broker,
            settings.clientId,
            settings.port,
          )
          ..secure = true
          ..keepAlivePeriod = 20
          ..disconnectOnNoResponsePeriod = 10
          ..autoReconnect = true
          ..logging(on: kDebugMode);

    bool isCurrent() => identical(client, _client);
    client.onConnected = () {
      if (isCurrent()) _setBrokerConnected(true);
    };
    client.onAutoReconnect = () {
      if (isCurrent()) _setBrokerConnected(false);
    };
    client.onDisconnected = () {
      if (isCurrent()) _setBrokerConnected(false);
    };
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(settings.clientId)
        .authenticateAs(settings.username, settings.password)
        .startClean();
    _client = client;

    try {
      await client.connect();
    } catch (e) {
      debugPrint('MQTT connection error: $e');
    }
    if (!isCurrent()) return;

    final status = client.connectionStatus;
    if (status?.state != MqttConnectionState.connected) {
      client.disconnect();
      if (!_isAuthError(status?.returnCode)) _scheduleRetry();
      return;
    }

    _hasConnected = true;
    for (final gate in gates) {
      client.subscribe(gate.statusTopic, MqttQos.atLeastOnce);
      client.subscribe(gate.ackTopic, MqttQos.atLeastOnce);
    }
    _updates = client.updates?.listen(handleMessages);
  }

  void pause() {
    _isPaused = true;
    _retryTimer?.cancel();
  }

  void resume() {
    _isPaused = false;
    final client = _client;
    final settings = _settings;
    if (client != null && _hasConnected) {
      client.doAutoReconnect(force: true);
    } else if (settings != null) {
      connect(settings);
    }
  }

  void openGate(Gate gate) {
    final client = _client;
    if (client == null || !_isBrokerConnected) return;

    final builder = MqttClientPayloadBuilder()..addString(gateStartCommand);
    client.publishMessage(
      gate.commandTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    _commands.start(gate.id);
  }

  @visibleForTesting
  void handleMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final publishMessage = message.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        publishMessage.payload.message,
      );

      for (final gate in gates) {
        if (message.topic == gate.statusTopic) {
          _gateOnline[gate.id] = payload == deviceOnlineStatus;
        } else if (message.topic == gate.ackTopic) {
          _commands.acknowledge(
            gate.id,
            accepted: payload == commandAcceptedAck,
          );
        }
      }
    }
    notifyListeners();
  }

  void _setBrokerConnected(bool isConnected) {
    _isBrokerConnected = isConnected;
    if (!isConnected) _gateOnline.updateAll((_, _) => false);
    notifyListeners();
  }

  bool _isAuthError(MqttConnectReturnCode? code) =>
      code == MqttConnectReturnCode.badUsernameOrPassword ||
      code == MqttConnectReturnCode.notAuthorized;

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_isPaused) return;

    _retryTimer = Timer(_retryDelay, () {
      final settings = _settings;
      if (settings != null) connect(settings);
    });
  }

  void _closeConnection() {
    _retryTimer?.cancel();
    _updates?.cancel();
    _updates = null;
    _hasConnected = false;

    final client = _client;
    _client = null;
    if (client != null) {
      client.autoReconnect = false;
      client.disconnect();
    }

    if (_isBrokerConnected) _setBrokerConnected(false);
  }

  @override
  void dispose() {
    _closeConnection();
    _commands.dispose();
    super.dispose();
  }
}

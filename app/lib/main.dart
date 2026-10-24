import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/gate.dart';
import 'screens/home_page.dart';
import 'screens/settings_page.dart';
import 'screens/status_page.dart';

void main() => runApp(const CerberApp());

class CerberApp extends StatelessWidget {
  const CerberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cerber',
      theme: ThemeData.dark(),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late MqttServerClient _client;
  bool _isBrokerConnected = false;
  final Map<String, bool> _gateOnline = {
    for (final gate in gates) gate.id: false,
  };

  String _broker = '';
  String _clientId = '';
  int _port = 8883;
  String _username = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    _loadSettingsAndConnect();
  }

  Future<void> _loadSettingsAndConnect() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _broker = prefs.getString('broker') ?? '';
      _clientId = prefs.getString('clientID') ?? '';
      _port = prefs.getInt('port') ?? 8883;
      _username = prefs.getString('username') ?? '';
      _password = prefs.getString('password') ?? '';
    });

    _connectToMqtt();
  }

  Future<void> _connectToMqtt() async {
    _client = MqttServerClient.withPort(_broker, _clientId, _port);
    _client.secure = true;
    _client.logging(on: true);
    _client.keepAlivePeriod = 20;

    _client.onConnected = () {
      setState(() => _isBrokerConnected = true);

      for (final gate in gates) {
        _client.subscribe(gate.statusTopic, MqttQos.atLeastOnce);
      }

      _client.updates?.listen((messages) {
        final received = messages[0];
        final publishMessage = received.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          publishMessage.payload.message,
        );

        for (final gate in gates) {
          if (received.topic == gate.statusTopic) {
            setState(
              () => _gateOnline[gate.id] = payload == deviceOnlineStatus,
            );
          }
        }
      });
    };

    _client.onDisconnected = () {
      setState(() {
        _isBrokerConnected = false;
        _gateOnline.updateAll((_, _) => false);
      });
    };

    _client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .authenticateAs(_username, _password)
        .startClean();

    try {
      await _client.connect();
    } catch (e) {
      debugPrint('MQTT connection error: $e');
      _client.disconnect();
    }
  }

  void _sendCommand(String topic, String message) {
    if (!_isBrokerConnected) return;

    final builder = MqttClientPayloadBuilder()..addString(message);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        sendCommand: _sendCommand,
        isBrokerConnected: _isBrokerConnected,
        gateOnline: _gateOnline,
      ),
      StatusPage(
        isBrokerConnected: _isBrokerConnected,
        gateOnline: _gateOnline,
      ),
      SettingsPage(onSave: _loadSettingsAndConnect),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerber'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.wifi), label: 'Status'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ustawienia',
          ),
        ],
      ),
    );
  }
}

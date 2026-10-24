import 'package:flutter/material.dart';

import 'models/mqtt_settings.dart';
import 'screens/home_page.dart';
import 'screens/settings_page.dart';
import 'screens/status_page.dart';
import 'services/mqtt_service.dart';

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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const _settingsTabIndex = 2;

  final _mqtt = MqttService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettingsAndConnect();
  }

  Future<void> _loadSettingsAndConnect() async {
    final settings = await MqttSettings.load();
    if (!settings.isComplete) {
      if (mounted) setState(() => _selectedIndex = _settingsTabIndex);
      return;
    }
    await _mqtt.connect(settings);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _mqtt.pause();
    } else if (state == AppLifecycleState.resumed) {
      _mqtt.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mqtt.dispose();
    super.dispose();
  }

  Widget _buildPage() {
    return switch (_selectedIndex) {
      0 => HomePage(
        onOpenGate: _mqtt.openGate,
        isBrokerConnected: _mqtt.isBrokerConnected,
        gateOnline: _mqtt.gateOnline,
        commandStatuses: _mqtt.commandStatuses,
      ),
      1 => StatusPage(
        isBrokerConnected: _mqtt.isBrokerConnected,
        gateOnline: _mqtt.gateOnline,
        deviceInfo: _mqtt.deviceInfo,
      ),
      _ => SettingsPage(onSave: _mqtt.connect),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerber'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: ListenableBuilder(
        listenable: _mqtt,
        builder: (context, _) => _buildPage(),
      ),
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

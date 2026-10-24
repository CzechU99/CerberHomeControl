import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/mqtt_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.onSave});

  final Future<void> Function(MqttSettings settings) onSave;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _clientIdController = TextEditingController();
  final _brokerController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _brokerController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = 'Wersja ${info.version}');
  }

  Future<void> _loadSettings() async {
    final settings = await MqttSettings.load();
    if (!mounted) return;
    setState(() {
      _clientIdController.text = settings.clientId;
      _brokerController.text = settings.broker;
      _portController.text = settings.port.toString();
      _usernameController.text = settings.username;
      _passwordController.text = settings.password;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = MqttSettings(
      broker: _brokerController.text.trim(),
      clientId: _clientIdController.text.trim(),
      port:
          int.tryParse(_portController.text.trim()) ?? MqttSettings.defaultPort,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
    await settings.save();
    widget.onSave(settings);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ustawienia zapisane')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text(
              'Ustawienia MQTT',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _clientIdController,
              decoration: const InputDecoration(labelText: 'Client ID'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Wpisz Client ID' : null,
            ),
            TextFormField(
              controller: _brokerController,
              decoration: const InputDecoration(labelText: 'Broker URL'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Wpisz adres brokera' : null,
            ),
            TextFormField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Wpisz port' : null,
            ),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  'Zapisz ustawienia',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _appVersion,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_settings.dart';
import '../models/mqtt_settings.dart';
import 'settings/general_settings_form.dart';
import 'settings/mqtt_settings_form.dart';

enum SettingsSection {
  mqtt('MQTT'),
  general('Ogólne');

  const SettingsSection(this.label);

  final String label;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.onSaveMqtt,
    required this.appSettings,
    required this.onAppSettingsChanged,
  });

  final Future<void> Function(MqttSettings settings) onSaveMqtt;
  final AppSettings appSettings;
  final ValueChanged<AppSettings> onAppSettingsChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsSection _section = SettingsSection.mqtt;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(
      () => _appVersion = 'Wersja ${info.version} (${info.buildNumber})',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<SettingsSection>(
            initialValue: _section,
            decoration: const InputDecoration(
              labelText: 'Ustawienia',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final section in SettingsSection.values)
                DropdownMenuItem(value: section, child: Text(section.label)),
            ],
            onChanged: (section) {
              if (section != null) setState(() => _section = section);
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: IndexedStack(
              index: _section.index,
              children: [
                MqttSettingsForm(onSave: widget.onSaveMqtt),
                GeneralSettingsForm(
                  settings: widget.appSettings,
                  onChanged: widget.onAppSettingsChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _appVersion,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

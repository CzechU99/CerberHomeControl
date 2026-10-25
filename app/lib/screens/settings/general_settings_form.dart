import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../models/gate.dart';

class GeneralSettingsForm extends StatelessWidget {
  const GeneralSettingsForm({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  static String _formatSeconds(Duration duration) {
    final seconds = duration.inMilliseconds / 1000;
    final text = seconds == seconds.roundToDouble()
        ? seconds.toStringAsFixed(0)
        : seconds.toStringAsFixed(1).replaceAll('.', ',');
    return '$text s';
  }

  Widget _buildDurationSetting({
    required String title,
    required String subtitle,
    required Duration value,
    required List<Duration> options,
    required ValueChanged<Duration> onSelected,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<Duration>(
        value: options.contains(value) ? value : null,
        items: [
          for (final option in options)
            DropdownMenuItem(
              value: option,
              child: Text(_formatSeconds(option)),
            ),
        ],
        onChanged: (selected) {
          if (selected != null) onSelected(selected);
        },
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildSectionHeader('Przyciski bram'),
        _buildDurationSetting(
          title: 'Czas przytrzymania',
          subtitle: 'Jak długo trzymać przycisk, aby otworzyć bramę',
          value: settings.holdDuration,
          options: AppSettings.holdDurationOptions,
          onSelected: (value) =>
              onChanged(settings.copyWith(holdDuration: value)),
        ),
        _buildDurationSetting(
          title: 'Czas na potwierdzenie',
          subtitle: 'Po tym czasie brak odpowiedzi sterownika to błąd',
          value: settings.ackTimeout,
          options: AppSettings.ackTimeoutOptions,
          onSelected: (value) =>
              onChanged(settings.copyWith(ackTimeout: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Wibracje'),
          subtitle: const Text('Przy otwarciu i wyniku komendy'),
          value: settings.vibrationEnabled,
          onChanged: (value) =>
              onChanged(settings.copyWith(vibrationEnabled: value)),
        ),
        _buildSectionHeader('Widoczne bramy'),
        for (final gate in gates)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(gate.statusLabel),
            value: settings.isGateVisible(gate.id),
            onChanged: (value) => onChanged(
              settings.withGateVisible(gate.id, visible: value ?? true),
            ),
          ),
      ],
    );
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.holdDuration = const Duration(milliseconds: 500),
    this.ackTimeout = const Duration(seconds: 5),
    this.vibrationEnabled = true,
    this.hiddenGateIds = const {},
  });

  static const List<Duration> holdDurationOptions = [
    Duration(milliseconds: 500),
    Duration(milliseconds: 1000),
    Duration(milliseconds: 1500),
    Duration(milliseconds: 2000),
  ];

  static const List<Duration> ackTimeoutOptions = [
    Duration(seconds: 3),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 15),
  ];

  static const _holdDurationKey = 'holdDurationMs';
  static const _ackTimeoutKey = 'ackTimeoutSeconds';
  static const _vibrationKey = 'vibrationEnabled';
  static const _hiddenGatesKey = 'hiddenGateIds';

  final Duration holdDuration;
  final Duration ackTimeout;
  final bool vibrationEnabled;
  final Set<String> hiddenGateIds;

  bool isGateVisible(String gateId) => !hiddenGateIds.contains(gateId);

  AppSettings copyWith({
    Duration? holdDuration,
    Duration? ackTimeout,
    bool? vibrationEnabled,
    Set<String>? hiddenGateIds,
  }) {
    return AppSettings(
      holdDuration: holdDuration ?? this.holdDuration,
      ackTimeout: ackTimeout ?? this.ackTimeout,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      hiddenGateIds: hiddenGateIds ?? this.hiddenGateIds,
    );
  }

  AppSettings withGateVisible(String gateId, {required bool visible}) {
    final hidden = {...hiddenGateIds};
    visible ? hidden.remove(gateId) : hidden.add(gateId);
    return copyWith(hiddenGateIds: hidden);
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = AppSettings();

    final holdMs = prefs.getInt(_holdDurationKey);
    final ackSeconds = prefs.getInt(_ackTimeoutKey);
    return AppSettings(
      holdDuration: holdMs != null
          ? Duration(milliseconds: holdMs)
          : defaults.holdDuration,
      ackTimeout: ackSeconds != null
          ? Duration(seconds: ackSeconds)
          : defaults.ackTimeout,
      vibrationEnabled:
          prefs.getBool(_vibrationKey) ?? defaults.vibrationEnabled,
      hiddenGateIds: (prefs.getStringList(_hiddenGatesKey) ?? []).toSet(),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_holdDurationKey, holdDuration.inMilliseconds);
    await prefs.setInt(_ackTimeoutKey, ackTimeout.inSeconds);
    await prefs.setBool(_vibrationKey, vibrationEnabled);
    await prefs.setStringList(_hiddenGatesKey, hiddenGateIds.toList());
  }
}

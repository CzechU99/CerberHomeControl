import 'package:cerber/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('uses the previous fixed behaviour as defaults', () async {
    final settings = await AppSettings.load();

    expect(settings.holdDuration, const Duration(milliseconds: 500));
    expect(settings.ackTimeout, const Duration(seconds: 5));
    expect(settings.vibrationEnabled, isTrue);
    expect(settings.isGateVisible('honda'), isTrue);
  });

  test('saves and loads all fields', () async {
    final saved = const AppSettings()
        .copyWith(
          holdDuration: const Duration(seconds: 2),
          ackTimeout: const Duration(seconds: 10),
          vibrationEnabled: false,
        )
        .withGateVisible('toyota', visible: false);

    await saved.save();
    final loaded = await AppSettings.load();

    expect(loaded.holdDuration, const Duration(seconds: 2));
    expect(loaded.ackTimeout, const Duration(seconds: 10));
    expect(loaded.vibrationEnabled, isFalse);
    expect(loaded.isGateVisible('toyota'), isFalse);
    expect(loaded.isGateVisible('honda'), isTrue);
  });

  test('shows a hidden gate again', () {
    final settings = const AppSettings()
        .withGateVisible('honda', visible: false)
        .withGateVisible('honda', visible: true);

    expect(settings.isGateVisible('honda'), isTrue);
  });
}

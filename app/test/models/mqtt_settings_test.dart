import 'package:cerber/models/mqtt_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('returns defaults when nothing is saved', () async {
    final settings = await MqttSettings.load();

    expect(settings.broker, isEmpty);
    expect(settings.port, MqttSettings.defaultPort);
    expect(settings.isComplete, isFalse);
  });

  test('saves and loads all fields', () async {
    const saved = MqttSettings(
      broker: 'broker.example.com',
      clientId: 'phone',
      port: 1883,
      username: 'user',
      password: 'secret',
    );

    await saved.save();
    final loaded = await MqttSettings.load();

    expect(loaded.broker, saved.broker);
    expect(loaded.clientId, saved.clientId);
    expect(loaded.port, saved.port);
    expect(loaded.username, saved.username);
    expect(loaded.password, saved.password);
    expect(loaded.isComplete, isTrue);
  });
}

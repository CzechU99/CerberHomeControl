import 'package:cerber/models/mqtt_settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('returns defaults when nothing is saved', () async {
    final settings = await MqttSettings.load();

    expect(settings.broker, isEmpty);
    expect(settings.password, isEmpty);
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

  test('keeps the password out of SharedPreferences', () async {
    const settings = MqttSettings(
      broker: 'broker.example.com',
      clientId: 'phone',
      port: 8883,
      username: 'user',
      password: 'secret',
    );

    await settings.save();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('password'), isNull);
    expect(await const FlutterSecureStorage().read(key: 'password'), 'secret');
  });

  test('moves a legacy password into secure storage', () async {
    SharedPreferences.setMockInitialValues({'password': 'legacy'});

    final loaded = await MqttSettings.load();

    final prefs = await SharedPreferences.getInstance();
    expect(loaded.password, 'legacy');
    expect(prefs.getString('password'), isNull);
    expect(await const FlutterSecureStorage().read(key: 'password'), 'legacy');
  });
}

import 'package:shared_preferences/shared_preferences.dart';

class MqttSettings {
  const MqttSettings({
    required this.broker,
    required this.clientId,
    required this.port,
    required this.username,
    required this.password,
  });

  static const int defaultPort = 8883;

  static const _brokerKey = 'broker';
  static const _clientIdKey = 'clientID';
  static const _portKey = 'port';
  static const _usernameKey = 'username';
  static const _passwordKey = 'password';

  final String broker;
  final String clientId;
  final int port;
  final String username;
  final String password;

  bool get isComplete => broker.isNotEmpty && clientId.isNotEmpty;

  static Future<MqttSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return MqttSettings(
      broker: prefs.getString(_brokerKey) ?? '',
      clientId: prefs.getString(_clientIdKey) ?? '',
      port: prefs.getInt(_portKey) ?? defaultPort,
      username: prefs.getString(_usernameKey) ?? '',
      password: prefs.getString(_passwordKey) ?? '',
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_brokerKey, broker);
    await prefs.setString(_clientIdKey, clientId);
    await prefs.setInt(_portKey, port);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passwordKey, password);
  }
}

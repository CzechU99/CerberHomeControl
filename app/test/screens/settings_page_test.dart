import 'package:cerber/models/mqtt_settings.dart';
import 'package:cerber/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Cerber',
      packageName: 'pl.cerber.homecontrol',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'broker': 'broker.example.com',
      'clientID': 'phone',
      'port': 8883,
      'username': 'user',
      'password': 'secret',
    });
  });

  Future<void> pumpSettingsPage(
    WidgetTester tester,
    Future<void> Function(MqttSettings) onSave,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsPage(onSave: onSave)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows saved broker and password', (tester) async {
    await pumpSettingsPage(tester, (_) async {});

    expect(find.text('broker.example.com'), findsOneWidget);
    expect(find.text('secret'), findsOneWidget);
    expect(find.text('Wersja 1.0.0 (1)'), findsOneWidget);
  });

  testWidgets('saving keeps the password when only the client id changes', (
    tester,
  ) async {
    MqttSettings? saved;
    await pumpSettingsPage(tester, (settings) async => saved = settings);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'phone'),
      'tablet',
    );
    await tester.tap(find.text('Zapisz ustawienia'));
    await tester.pumpAndSettle();

    expect(saved?.clientId, 'tablet');
    expect(saved?.password, 'secret');
    expect((await MqttSettings.load()).password, 'secret');
  });
}

import 'package:cerber/main.dart';
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
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens settings when MQTT is not configured', (tester) async {
    await tester.pumpWidget(const CerberApp());
    await tester.pumpAndSettle();

    expect(find.text('Ustawienia MQTT'), findsOneWidget);
  });
}

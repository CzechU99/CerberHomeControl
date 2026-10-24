import 'package:cerber/models/gate.dart';
import 'package:cerber/screens/home_page.dart';
import 'package:cerber/services/command_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final honda = gates.first;

  Future<List<Gate>> pumpHomePage(
    WidgetTester tester, {
    CommandStatus hondaStatus = CommandStatus.idle,
  }) async {
    final opened = <Gate>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            onOpenGate: opened.add,
            isBrokerConnected: true,
            gateOnline: {for (final gate in gates) gate.id: true},
            commandStatuses: {honda.id: hondaStatus},
          ),
        ),
      ),
    );
    return opened;
  }

  ElevatedButton hondaButton(WidgetTester tester) => tester.widget(
    find.ancestor(
      of: find.text(honda.buttonLabel),
      matching: find.byType(ElevatedButton),
    ),
  );

  testWidgets('opens the gate on long press', (tester) async {
    final opened = await pumpHomePage(tester);

    await tester.longPress(find.text(honda.buttonLabel));

    expect(opened, [honda]);
  });

  testWidgets('a short tap only shows a hint', (tester) async {
    final opened = await pumpHomePage(tester);

    await tester.tap(find.text(honda.buttonLabel));
    await tester.pump();

    expect(opened, isEmpty);
    expect(
      find.text('Przytrzymaj przycisk, aby otworzyć bramę'),
      findsOneWidget,
    );
  });

  testWidgets('shows progress and blocks taps while waiting for ack', (
    tester,
  ) async {
    await pumpHomePage(tester, hondaStatus: CommandStatus.pending);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(hondaButton(tester).onPressed, isNull);
    expect(hondaButton(tester).onLongPress, isNull);
  });

  testWidgets('shows the result of the command', (tester) async {
    await pumpHomePage(tester, hondaStatus: CommandStatus.confirmed);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await pumpHomePage(tester, hondaStatus: CommandStatus.failed);
    expect(find.byIcon(Icons.error), findsOneWidget);
  });
}

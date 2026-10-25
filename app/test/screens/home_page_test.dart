import 'package:cerber/models/gate.dart';
import 'package:cerber/screens/home_page.dart';
import 'package:cerber/services/command_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final honda = gates.first;
  const holdDuration = Duration(seconds: 1);
  const hint = 'Przytrzymaj przycisk, aby otworzyć bramę';

  Future<List<Gate>> pumpHomePage(
    WidgetTester tester, {
    List<Gate>? visibleGates,
    CommandStatus hondaStatus = CommandStatus.idle,
  }) async {
    final opened = <Gate>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            gates: visibleGates ?? gates,
            onOpenGate: opened.add,
            isBrokerConnected: true,
            gateOnline: {for (final gate in gates) gate.id: true},
            commandStatuses: {honda.id: hondaStatus},
            holdDuration: holdDuration,
            vibrationEnabled: true,
          ),
        ),
      ),
    );
    return opened;
  }

  Future<void> holdHonda(WidgetTester tester, Duration duration) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.text(honda.buttonLabel)),
    );
    await tester.pump();
    await tester.pump(duration);
    await gesture.up();
    await tester.pump();
  }

  testWidgets('opens the gate after holding for the set duration', (
    tester,
  ) async {
    final opened = await pumpHomePage(tester);

    await holdHonda(tester, holdDuration + const Duration(milliseconds: 50));

    expect(opened, [honda]);
    expect(find.text(hint), findsNothing);
  });

  testWidgets('releasing too early only shows a hint', (tester) async {
    final opened = await pumpHomePage(tester);

    await holdHonda(tester, const Duration(milliseconds: 500));

    expect(opened, isEmpty);
    expect(find.text(hint), findsOneWidget);
  });

  testWidgets('ignores holds while waiting for ack', (tester) async {
    final opened = await pumpHomePage(
      tester,
      hondaStatus: CommandStatus.pending,
    );

    await holdHonda(tester, holdDuration + const Duration(milliseconds: 50));
    expect(opened, isEmpty);
  });

  FadeTransition flash(WidgetTester tester) =>
      tester.widget(find.byKey(const ValueKey('gate-button-flash')).first);

  Color flashColor(WidgetTester tester) => tester
      .widget<ColoredBox>(
        find
            .descendant(
              of: find.byKey(const ValueKey('gate-button-flash')).first,
              matching: find.byType(ColoredBox),
            )
            .first,
      )
      .color;

  for (final (status, color) in [
    (CommandStatus.confirmed, Colors.green),
    (CommandStatus.failed, Colors.red),
  ]) {
    testWidgets('blinks ${status.name} result', (tester) async {
      await pumpHomePage(tester, hondaStatus: CommandStatus.pending);
      expect(flash(tester).opacity.value, 0);

      await pumpHomePage(tester, hondaStatus: status);
      await tester.pump(const Duration(milliseconds: 225));

      expect(flash(tester).opacity.value, greaterThan(0.5));
      expect(flashColor(tester), color);

      await tester.pumpAndSettle();
      expect(flash(tester).opacity.value, 0);
    });
  }

  testWidgets('shows only the visible gates', (tester) async {
    await pumpHomePage(tester, visibleGates: [honda]);

    expect(find.text(honda.buttonLabel), findsOneWidget);
    expect(find.text(gates.last.buttonLabel), findsNothing);
  });

  testWidgets('explains when all gates are hidden', (tester) async {
    await pumpHomePage(tester, visibleGates: []);

    expect(find.textContaining('Wszystkie bramy są ukryte'), findsOneWidget);
  });
}

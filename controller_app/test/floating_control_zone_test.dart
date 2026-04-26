import 'package:controller_app/src/features/control/widgets/floating_control_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('vertical floating control maps upward drag to positive values', (
    tester,
  ) async {
    final values = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingControlZone(
              direction: FloatingControlDirection.vertical,
              onChanged: values.add,
            ),
          ),
        ),
      ),
    );

    final zone = find.byType(FloatingControlZone);
    final gesture = await tester.startGesture(tester.getCenter(zone));
    await tester.pump();

    expect(values.last, 0);
    expect(find.byKey(floatingControlBaseKey), findsNothing);
    expect(find.byKey(floatingControlThumbKey), findsOneWidget);
    expect(find.byKey(floatingControlPositiveKey), findsNothing);
    expect(find.byKey(floatingControlNegativeKey), findsNothing);

    await gesture.moveBy(const Offset(0, -162));
    await tester.pump();

    expect(values.last, closeTo(1, 0.001));
    expect(find.byKey(floatingControlBaseKey), findsOneWidget);
    expect(find.byKey(floatingControlPositiveKey), findsOneWidget);
    expect(find.byKey(floatingControlNegativeKey), findsNothing);

    await gesture.up();
    await tester.pump();

    expect(values.last, 0);
    expect(find.byKey(floatingControlBaseKey), findsNothing);
    expect(find.byKey(floatingControlThumbKey), findsNothing);
  });

  testWidgets('horizontal floating control maps left drag to negative values', (
    tester,
  ) async {
    final values = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingControlZone(
              direction: FloatingControlDirection.horizontal,
              onChanged: values.add,
            ),
          ),
        ),
      ),
    );

    final zone = find.byType(FloatingControlZone);
    final gesture = await tester.startGesture(tester.getCenter(zone));
    await tester.pump();

    await gesture.moveBy(const Offset(-81, 0));
    await tester.pump();

    expect(values.last, closeTo(-1, 0.001));
    expect(find.byKey(floatingControlBaseKey), findsOneWidget);
    expect(find.byKey(floatingControlPositiveKey), findsNothing);
    expect(find.byKey(floatingControlNegativeKey), findsOneWidget);

    await gesture.up();
    await tester.pump();

    expect(values.last, 0);
  });

  testWidgets('positive-only vertical control ignores downward drag', (
    tester,
  ) async {
    final values = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingControlZone(
              direction: FloatingControlDirection.vertical,
              allowNegative: false,
              onChanged: values.add,
            ),
          ),
        ),
      ),
    );

    final zone = find.byType(FloatingControlZone);
    final gesture = await tester.startGesture(tester.getCenter(zone));
    await tester.pump();

    await gesture.moveBy(const Offset(0, 81));
    await tester.pump();

    expect(values.last, 0);
    expect(find.byKey(floatingControlBaseKey), findsNothing);
    expect(find.byKey(floatingControlPositiveKey), findsNothing);
    expect(find.byKey(floatingControlNegativeKey), findsNothing);

    await gesture.up();
    await tester.pump();

    final secondGesture = await tester.startGesture(tester.getCenter(zone));
    await tester.pump();

    await secondGesture.moveBy(const Offset(0, -81));
    await tester.pump();

    expect(values.last, greaterThan(0));
    expect(find.byKey(floatingControlPositiveKey), findsOneWidget);
    expect(find.byKey(floatingControlNegativeKey), findsNothing);
  });
}

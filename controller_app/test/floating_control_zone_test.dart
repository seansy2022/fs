import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';

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
            child: VerticalFloatingControlZone(
              onChanged: values.add,
            ),
          ),
        ),
      ),
    );

    final zone = find.byType(VerticalFloatingControlZone);
    final gesture = await tester.startGesture(tester.getCenter(zone));
    await tester.pump();

    expect(values.last, 0);
    expect(find.byKey(floatingControlBaseKey), findsOneWidget);
    expect(find.byKey(floatingControlThumbKey), findsOneWidget);
    expect(find.byKey(floatingControlPositiveKey), findsOneWidget);
    expect(find.byKey(floatingControlNegativeKey), findsOneWidget);

    await gesture.moveBy(const Offset(0, -162));
    await tester.pump();

    expect(values.last, closeTo(1, 0.001));
    expect(find.byKey(floatingControlBaseKey), findsOneWidget);
    expect(find.byKey(floatingControlPositiveKey), findsOneWidget);
    expect(find.byKey(floatingControlNegativeKey), findsOneWidget);

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
    expect(find.byKey(floatingControlNegativeKey), findsOneWidget);
    expect(find.byKey(floatingControlPositiveKey), findsOneWidget);

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
            child: VerticalFloatingControlZone(
              allowNegative: false,
              onChanged: values.add,
            ),
          ),
        ),
      ),
    );

    final zone = find.byType(VerticalFloatingControlZone);
    final gesture = await tester.startGesture(tester.getCenter(zone));
    await tester.pump();

    await gesture.moveBy(const Offset(0, 81));
    await tester.pump();

    expect(values.last, 0);
    expect(find.byKey(floatingControlBaseKey), findsOneWidget);
    expect(find.byKey(floatingControlPositiveKey), findsOneWidget);
    expect(find.byKey(floatingControlNegativeKey), findsOneWidget);

    await gesture.up();
    await tester.pump();

    final secondGesture = await tester.startGesture(tester.getCenter(zone));
    await tester.pump();

    await secondGesture.moveBy(const Offset(0, -81));
    await tester.pump();

    expect(values.last, greaterThan(0));
    expect(find.byKey(floatingControlPositiveKey), findsOneWidget);
    expect(find.byKey(floatingControlNegativeKey), findsOneWidget);
  });

  testWidgets(
    'vertical floating control keeps first gesture intent within one touch',
    (tester) async {
      final values = <double>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: VerticalFloatingControlZone(
                onChanged: values.add,
              ),
            ),
          ),
        ),
      );

      final zone = find.byType(VerticalFloatingControlZone);
      final gesture = await tester.startGesture(tester.getCenter(zone));
      await tester.pump();

      await gesture.moveBy(const Offset(0, -81));
      await tester.pump();
      expect(values.last, greaterThan(0));

      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      expect(values.last, 0);

      await gesture.up();
      await tester.pump();
      expect(values.last, 0);
    },
  );

  testWidgets(
    'vertical floating control does not lock downward from tiny initial jitter',
    (tester) async {
      final values = <double>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: VerticalFloatingControlZone(
                onChanged: values.add,
              ),
            ),
          ),
        ),
      );

      final zone = find.byType(VerticalFloatingControlZone);
      final gesture = await tester.startGesture(tester.getCenter(zone));
      await tester.pump();

      await gesture.moveBy(const Offset(0, 4));
      await tester.pump();

      await gesture.moveBy(const Offset(0, -40));
      await tester.pump();

      expect(values.last, greaterThan(0));

      await gesture.up();
      await tester.pump();
    },
  );

  testWidgets(
    'floating control clamps touch origin to keep control fully visible',
    (tester) async {
      final values = <double>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingControlZone(
                direction: FloatingControlDirection.horizontal,
                width: 300,
                height: 300,
                onChanged: values.add,
              ),
            ),
          ),
        ),
      );

      final zone = find.byType(FloatingControlZone);
      final zoneRect = tester.getRect(zone);
      final gesture = await tester.startGesture(
        zoneRect.topLeft + const Offset(5, 5),
      );
      await tester.pump();

      expect(values.last, 0);
      expect(find.byKey(floatingControlThumbKey), findsOneWidget);

      final thumbRect = tester.getRect(find.byKey(floatingControlThumbKey));
      final localCenter = thumbRect.center - zoneRect.topLeft;
      expect(localCenter.dx, closeTo(103, 1.0));
      expect(localCenter.dy, closeTo(50, 1.0));

      await gesture.up();
      await tester.pump();
      expect(find.byKey(floatingControlThumbKey), findsNothing);
    },
  );

  testWidgets(
    'vertical floating control does not throw when zone is shorter than control height',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: VerticalFloatingControlZone(
                  width: 120,
                  height: 120,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      final zone = find.byType(VerticalFloatingControlZone);
      final gesture = await tester.startGesture(tester.getCenter(zone));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(floatingControlThumbKey), findsOneWidget);

      await gesture.up();
      await tester.pump();
    },
  );
}

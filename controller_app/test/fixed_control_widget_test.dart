import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'fixed horizontal control shows both endpoints and hides thumb when idle',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Control(
                direction: ControlSliderDirection.horizontal,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(controlPositiveKey), findsOneWidget);
      expect(find.byKey(controlNegativeKey), findsOneWidget);
      expect(find.byKey(controlThumbKey), findsNothing);
    },
  );

  testWidgets(
    'fixed vertical control shows both endpoints and hides thumb when idle',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Control(
                direction: ControlSliderDirection.vertical,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(controlPositiveKey), findsOneWidget);
      expect(find.byKey(controlNegativeKey), findsOneWidget);
      expect(find.byKey(controlThumbKey), findsNothing);
    },
  );

  testWidgets(
    'single-direction fixed control still renders endpoints when idle',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Control(
                direction: ControlSliderDirection.vertical,
                allowNegative: false,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(controlPositiveKey), findsOneWidget);
      expect(find.byKey(controlNegativeKey), findsOneWidget);
      expect(find.byKey(controlThumbKey), findsNothing);
    },
  );
}

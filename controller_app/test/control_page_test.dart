import 'package:controller_app/src/features/control/pages/control_page.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gyro override stays off when control-page gyro switch is off', () {
    expect(
      shouldUseGyroControlOverride(
        gyroEnabled: false,
        gyroMode: GyroMode.directionOnly,
      ),
      isFalse,
    );
    expect(
      shouldUseGyroControlOverride(
        gyroEnabled: false,
        gyroMode: GyroMode.throttleOnly,
      ),
      isFalse,
    );
  });

  test('gyro override only applies for enabled single-axis gyro modes', () {
    expect(
      shouldUseGyroControlOverride(
        gyroEnabled: true,
        gyroMode: GyroMode.directionOnly,
      ),
      isTrue,
    );
    expect(
      shouldUseGyroControlOverride(
        gyroEnabled: true,
        gyroMode: GyroMode.throttleOnly,
      ),
      isTrue,
    );
    expect(
      shouldUseGyroControlOverride(gyroEnabled: true, gyroMode: GyroMode.all),
      isFalse,
    );
  });

  testWidgets('gyro direction hint keeps the dot above the up arrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: buildGyroDirectionVerticalAlignmentPreviewForTest(
              upArrow: true,
            ),
          ),
        ),
      ),
    );

    final dotCenter = tester.getCenter(find.byKey(gyroHintDotKey));
    final arrowCenter = tester.getCenter(find.byKey(gyroHintUpArrowKey));

    expect(find.byKey(gyroHintDownArrowKey), findsNothing);
    expect(dotCenter.dy, lessThan(arrowCenter.dy));
  });

  testWidgets('gyro direction hint keeps the dot above the down arrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: buildGyroDirectionVerticalAlignmentPreviewForTest(
              upArrow: false,
            ),
          ),
        ),
      ),
    );

    final dotCenter = tester.getCenter(find.byKey(gyroHintDotKey));
    final arrowCenter = tester.getCenter(find.byKey(gyroHintDownArrowKey));

    expect(find.byKey(gyroHintUpArrowKey), findsNothing);
    expect(dotCenter.dy, lessThan(arrowCenter.dy));
  });

  testWidgets('gyro direction preview no longer reuses the shared Control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: buildGyroDirectionVerticalAlignmentPreviewForTest(
              upArrow: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Control), findsNothing);
  });

  testWidgets('downward gyro preview responds immediately to downward drag', (
    tester,
  ) async {
    double lastValue = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: buildGyroDirectionVerticalAlignmentPreviewForTest(
              upArrow: false,
              onChanged: (value) {
                lastValue = value;
              },
            ),
          ),
        ),
      ),
    );

    final stick = find.byKey(gyroHintStickProbeKey);
    final topCenter = tester.getTopLeft(stick) + const Offset(50, 4);
    final gesture = await tester.startGesture(topCenter);
    await tester.pump();
    final thumbBeforeMove = tester.getRect(find.byKey(gyroHintThumbKey));
    await gesture.moveBy(const Offset(0, 12));
    await tester.pump();
    final thumbAfterMove = tester.getRect(find.byKey(gyroHintThumbKey));

    expect(lastValue, lessThan(0));
    expect(thumbAfterMove.top, greaterThan(thumbBeforeMove.top));

    await gesture.up();
    await tester.pump();
  });
}

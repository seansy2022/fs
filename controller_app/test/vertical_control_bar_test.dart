import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  testWidgets('vertical control bar requires release before reversing', (
    tester,
  ) async {
    final values = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RCControllSider(
              direction: RCControllSiderDirection.vertical,
              lockSignUntilRelease: true,
              onChanged: values.add,
            ),
          ),
        ),
      ),
    );

    final slider = find.byType(RCControllSider);
    final center = tester.getCenter(slider);

    final forwardDrag = await tester.startGesture(center);
    await tester.pump();
    await forwardDrag.moveBy(const Offset(0, -45));
    await tester.pump();
    final beforeReverseAttempt = values.last;

    await forwardDrag.moveBy(const Offset(0, 100));
    await tester.pump();

    expect(beforeReverseAttempt, greaterThan(0));
    expect(values.last, 0);

    await forwardDrag.up();
    await tester.pump();

    final reverseDrag = await tester.startGesture(center);
    await tester.pump();
    await reverseDrag.moveBy(const Offset(0, 45));
    await tester.pump();

    expect(values.last, lessThan(0));

    await reverseDrag.up();
  });
}

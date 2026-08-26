import 'package:controller_app/src/features/control/widgets/floating_single_direction_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('单向浮动控件只显示一个箭头并限制反向输出', (tester) async {
    final values = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 240,
            child: FloatingSingleDirectionControl(
              axis: FloatingControlAxis.horizontal,
              positive: false,
              onChanged: values.add,
            ),
          ),
        ),
      ),
    );
    final control = find.byType(FloatingSingleDirectionControl);
    final gesture = await tester.startGesture(tester.getCenter(control));
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey<String>('floating-single-arrow-horizontal-false'),
      ),
      findsOneWidget,
    );
    final arrow = find.byKey(
      const ValueKey<String>('floating-single-arrow-horizontal-false'),
    );
    final thumb = find.byKey(const ValueKey<String>('floating-single-thumb'));
    expect(
      tester.getRect(arrow).right,
      closeTo(tester.getCenter(thumb).dx, 0.1),
    );
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    expect(values.last, 0);
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();
    expect(values.last, lessThan(0));
    await gesture.up();
    await tester.pump();
    expect(values.last, 0);
    expect(
      find.byKey(const ValueKey<String>('floating-single-thumb')),
      findsNothing,
    );
  });
}

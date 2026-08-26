import 'package:controller_app/src/features/control/widgets/single_hand_control/floating_four_direction_control.dart';
import 'package:controller_app/src/features/control/widgets/single_hand_control/four_direction_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('初始隐藏，拖动输出二维值，松手归零', (tester) async {
    final values = <FourDirectionValue>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: FloatingFourDirectionControl(onChanged: values.add),
          ),
        ),
      ),
    );
    final control = find.byType(FloatingFourDirectionControl);
    expect(find.byKey(floatingFourDirectionThumbKey), findsNothing);
    final gesture = await tester.startGesture(tester.getCenter(control));
    await gesture.moveBy(const Offset(60, -60));
    await tester.pump();
    expect(values.last.steering, greaterThan(0));
    expect(values.last.throttle, greaterThan(0));
    expect(find.byKey(floatingFourDirectionThumbKey), findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(values.last.steering, 0);
    expect(values.last.throttle, 0);
    expect(find.byKey(floatingFourDirectionThumbKey), findsNothing);
  });

  testWidgets('边缘按下时四方向视觉保持在操控面内', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 320,
            child: FloatingFourDirectionControl(onChanged: (_) {}),
          ),
        ),
      ),
    );
    final control = find.byType(FloatingFourDirectionControl);
    final gesture = await tester.startGesture(
      tester.getTopLeft(control) + const Offset(2, 2),
    );
    await tester.pump();
    final controlRect = tester.getRect(control);
    final normal = find.byKey(
      const ValueKey<String>('four-direction-normal-left'),
    );
    expect(tester.getRect(normal).left, greaterThanOrEqualTo(controlRect.left));
    expect(tester.getRect(normal).top, greaterThanOrEqualTo(controlRect.top));
    await gesture.cancel();
  });
}

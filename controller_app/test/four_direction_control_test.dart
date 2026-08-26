import 'package:controller_app/src/features/control/widgets/single_hand_control/four_direction_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('205px 四方向控制区由四个 100px 单元组成', () {
    expect(fourDirectionCellSideFor(const Size(205, 205)), 100);
  });

  testWidgets('有方向和油门值时同时高亮对应方向，松手后清除', (tester) async {
    final values = <FourDirectionValue>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 224,
            height: 224,
            child: FourDirectionControl(onChanged: values.add),
          ),
        ),
      ),
    );

    final control = find.byType(FourDirectionControl);
    final center = tester.getCenter(control);
    expect(find.byKey(fourDirectionThumbKey), findsNothing);
    for (final direction in <String>['forward', 'reverse', 'left', 'right']) {
      expect(
        find.byKey(ValueKey<String>('four-direction-normal-$direction')),
        findsOneWidget,
      );
    }

    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(-80, -80));
    await tester.pump();

    expect(find.byKey(fourDirectionThumbKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('four-direction-highlight-forward')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('four-direction-highlight-left')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('four-direction-highlight-reverse')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('four-direction-highlight-right')),
      findsNothing,
    );

    await gesture.up();
    await tester.pump();

    expect(values.last.steering, 0);
    expect(values.last.throttle, 0);
    expect(find.byKey(fourDirectionThumbKey), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('four-direction-highlight-left')),
      findsNothing,
    );
  });
}

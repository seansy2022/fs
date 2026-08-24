import 'package:controller_app/src/features/control/widgets/directional_steering_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('左右箭头可拖动输出对应方向，松手回中', (tester) async {
    final values = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              DirectionalSteeringButton(direction: -1, onChanged: values.add),
              DirectionalSteeringButton(direction: 1, onChanged: values.add),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('directional-steering-asset-left')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('directional-steering-asset-right')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('directional-steering-thumb-left')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('directional-steering-thumb-right')),
      findsNothing,
    );
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    expect(find.text('左转'), findsNothing);
    expect(find.text('右转'), findsNothing);

    final leftButton = find.byKey(const ValueKey('directional-steering-left'));
    final leftStart = tester.getTopLeft(leftButton) + const Offset(90, 50);
    final leftGesture = await tester.startGesture(leftStart);
    await leftGesture.moveBy(const Offset(-50, 0));
    await tester.pump();
    expect(values.last, lessThan(0));
    expect(
      find.byKey(const ValueKey('directional-steering-thumb-left')),
      findsOneWidget,
    );
    final leftThumbPosition = tester.widget<Positioned>(
      find.byKey(const ValueKey('directional-steering-thumb-position-left')),
    );
    await leftGesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    expect(
      tester
          .widget<Positioned>(
            find.byKey(
              const ValueKey('directional-steering-thumb-position-left'),
            ),
          )
          .left,
      lessThan(leftThumbPosition.left!),
    );
    await leftGesture.up();
    expect(values.last, 0);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('directional-steering-thumb-left')),
      findsNothing,
    );

    final rightButton = find.byKey(
      const ValueKey('directional-steering-right'),
    );
    final rightStart = tester.getTopLeft(rightButton) + const Offset(10, 50);
    final rightGesture = await tester.startGesture(rightStart);
    await rightGesture.moveBy(const Offset(50, 0));
    await tester.pump();
    expect(values.last, greaterThan(0));
    await rightGesture.up();
    expect(values.last, 0);
  });
}

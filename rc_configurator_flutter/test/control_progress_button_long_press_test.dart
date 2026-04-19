import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  testWidgets('tap triggers once and long press repeats', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RCIconButton(
              plus: true,
              active: false,
              onTap: () => count++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(RCIconButton));
    await tester.pump();
    expect(count, 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(RCIconButton)),
    );
    await tester.pump(const Duration(milliseconds: 650));
    final beforeRepeat = count;
    expect(beforeRepeat, greaterThan(1));

    await tester.pump(const Duration(milliseconds: 220));
    expect(count, greaterThan(beforeRepeat));

    await gesture.up();
    await tester.pump();
    final afterUp = count;
    await tester.pump(const Duration(milliseconds: 240));
    expect(count, afterUp);
  });
}

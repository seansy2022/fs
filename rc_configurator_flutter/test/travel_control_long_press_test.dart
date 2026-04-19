import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  testWidgets('travel control step button repeats on long press', (tester) async {
    var leftChanges = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TravelControl(
            label: 'CH1',
            lValue: 50,
            rValue: 50,
            onLChange: (_) => leftChanges++,
            onRChange: (_) {},
          ),
        ),
      ),
    );

    // 找到左侧的 + 按钮。TravelControl 内部逻辑：左侧 Row 先是 RCIconButton(-) 然后是 RCIconButton(+)
    // 所以 find.byType(RCIconButton) 会找到 4 个。第 2 个是左侧的 +
    final leftPlus = find.byType(RCIconButton).at(1);
    
    await tester.tap(leftPlus);
    await tester.pump();
    expect(leftChanges, 1);

    final gesture = await tester.startGesture(tester.getCenter(leftPlus));
    await tester.pump(const Duration(milliseconds: 650));
    final beforeRepeat = leftChanges;
    expect(beforeRepeat, greaterThan(1));

    await tester.pump(const Duration(milliseconds: 220));
    expect(leftChanges, greaterThan(beforeRepeat));

    await gesture.up();
    await tester.pump();
    final afterUp = leftChanges;
    await tester.pump(const Duration(milliseconds: 240));
    expect(leftChanges, afterUp);
  });
}

import 'package:controller_app/src/features/settings/view/gyro/gyro_axis_calibration_panel.dart';
import 'package:controller_app/src/features/settings/widgets/numeric_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('点击角度值时通过弹窗提交并回写草稿', (tester) async {
    final controller = TextEditingController(text: '45');
    var changeCount = 0;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GyroDegreeInput(
            data: GyroDegreeInputData(label: '前进最大角度', controller: controller),
            showError: false,
            onChanged: () => changeCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('gyro-degree-input-前进最大角度')));
    await tester.pumpAndSettle();
    expect(find.byType(NumericInputDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), '60');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.text, '60');
    expect(changeCount, 1);
    expect(find.text('60'), findsOneWidget);
  });

  testWidgets('取消弹窗不会更改角度草稿', (tester) async {
    final controller = TextEditingController(text: '-45');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GyroDegreeInput(
            data: GyroDegreeInputData(label: '后退最大角度', controller: controller),
            showError: false,
            onChanged: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('gyro-degree-input-后退最大角度')));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    expect(controller.text, '-45');
  });
}

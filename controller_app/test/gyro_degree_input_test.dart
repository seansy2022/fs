import 'package:controller_app/src/features/settings/view/gyro/gyro_axis_calibration_panel.dart';
import 'package:controller_app/src/features/settings/widgets/numeric_input_dialog.dart';
import 'package:controller_app/src/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('英文体感校准文案不再回退为中文或固定分行', () {
    const localization = AppLocalizations(Locale('en'));

    expect(localization.text('体感校准：'), 'Motion Calibration:');
    expect(localization.text('保存'), 'Save');
    expect(
      localization.text('可通过此功能，校准最大通道行程对应的陀螺仪角度'),
      'Calibrate the gyroscope angle for maximum channel travel.',
    );
    expect(
      localization
          .text(
            '自定义X控制校准\n根据右图示意和实时旋转角度\n参考，请前后转动手机选择适\n合自己的控制角度，并输入对\n应控制角度完成自定义控制校\n准。',
          )
          .split('\n'),
      hasLength(2),
    );
  });

  testWidgets('英文角度标签比中文小一个字号', (tester) async {
    final controller = TextEditingController(text: '45');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: GyroDegreeInput(
            data: GyroDegreeInputData(label: '前进最大角度', controller: controller),
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('前进最大角度')).style?.fontSize, 10);
  });

  testWidgets('点击角度值时通过弹窗提交并回写草稿', (tester) async {
    final controller = TextEditingController(text: '45');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GyroDegreeInput(
            data: GyroDegreeInputData(label: '前进最大角度', controller: controller),
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

  testWidgets('不符合规范的角度在完成时恢复原值并提示', (tester) async {
    final controller = TextEditingController(text: '45');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GyroDegreeInput(
            data: GyroDegreeInputData(label: '前进最大角度', controller: controller),
            isInputValid: (_, _) => false,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('gyro-degree-input-前进最大角度')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '50');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.text, '45');
    expect(find.text('输入不符合规范，已恢复原值。'), findsOneWidget);
  });
}

import 'package:controller_app/src/features/control/widgets/steering_indicator_row.dart';
import 'package:controller_app/src/features/control/view/control_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  test('removes the embedded steering label from SVG', () {
    const svg =
        '<svg><g><text transform="translate(28, 58)">方向</text>'
        '</g><defs /></svg>';

    expect(
      removeEmbeddedDialLabel(svg, throttle: false),
      '<svg><defs /></svg>',
    );
  });

  test('removes the embedded throttle label path from SVG', () {
    const svg =
        '<svg><g><g filter="url(#filter_2_537)">油门</g></g>'
        '<defs /></svg>';

    expect(removeEmbeddedDialLabel(svg, throttle: true), '<svg><defs /></svg>');
  });

  testWidgets('drive mode labels stay on one line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RcDriveModeSwitch(mode: RcDriveMode.low, onChanged: (_) {}),
        ),
      ),
    );

    final labels = tester.widgetList<Text>(find.byType(Text)).toList();
    expect(
      labels.map((label) => label.data),
      containsAll(<String>['LOW', 'HIGH']),
    );
    expect(
      labels.where((label) => label.data == 'LOW').single.softWrap,
      isFalse,
    );
    expect(labels.where((label) => label.data == 'HIGH').single.maxLines, 1);
  });

  testWidgets('compact drive labels follow the active language', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        home: Builder(
          builder: (context) => Text(
            '${compactDriveModeLabel(context, high: false)} '
            '${compactDriveModeLabel(context, high: true)}',
          ),
        ),
      ),
    );

    expect(find.text('低速 高速'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  testWidgets('rear minus at 100 only switches to F', (tester) async {
    await _pumpDrive(tester, front: 100, rear: 100, leftSelected: false);

    await tester.tap(_minusButton());
    await tester.pump();

    final control = tester.widget<DriveMixingControl>(
      find.byType(DriveMixingControl),
    );
    expect(control.leftSelected, isTrue);
    expect(control.frontRatio, 100);
    expect(control.rearRatio, 100);
  });

  testWidgets('rear plus decreases rear ratio', (tester) async {
    await _pumpDrive(tester, front: 100, rear: 100, leftSelected: false);

    await tester.tap(_plusButton());
    await tester.pump();

    expect(find.text('R:99%'), findsOneWidget);
    final control = tester.widget<DriveMixingControl>(
      find.byType(DriveMixingControl),
    );
    expect(control.leftSelected, isFalse);
  });

  testWidgets('front plus at 100 only switches to R', (tester) async {
    await _pumpDrive(tester, front: 100, rear: 100, leftSelected: true);

    await tester.tap(_plusButton());
    await tester.pump();

    final control = tester.widget<DriveMixingControl>(
      find.byType(DriveMixingControl),
    );
    expect(control.leftSelected, isFalse);
    expect(control.frontRatio, 100);
    expect(control.rearRatio, 100);
  });
}

Finder _minusButton() {
  return find.byWidgetPredicate((widget) {
    return widget is RCIconButton &&
        widget.plus == false &&
        widget.text == null;
  });
}

Finder _plusButton() {
  return find.byWidgetPredicate((widget) {
    return widget is RCIconButton && widget.plus == true && widget.text == null;
  });
}

Future<void> _pumpDrive(
  WidgetTester tester, {
  required int front,
  required int rear,
  required bool leftSelected,
}) {
  return tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(0.8)),
      child: MaterialApp(
        home: _DriveHarness(
          front: front,
          rear: rear,
          leftSelected: leftSelected,
        ),
      ),
    ),
  );
}

class _DriveHarness extends StatefulWidget {
  const _DriveHarness({
    required this.front,
    required this.rear,
    required this.leftSelected,
  });

  final int front;
  final int rear;
  final bool leftSelected;

  @override
  State<_DriveHarness> createState() => _DriveHarnessState();
}

class _DriveHarnessState extends State<_DriveHarness> {
  late int front = widget.front;
  late int rear = widget.rear;
  late bool leftSelected = widget.leftSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DriveMixingControl(
        selectedChannel: 'CH3',
        frontRatio: front,
        rearRatio: rear,
        leftSelected: leftSelected,
        mode: DriveLayout.mixed,
        onChannelTap: () {},
        onModeChange: (_) {},
        onRatioChange: (nextFront, nextRear, nextLeftSelected) {
          setState(() {
            front = nextFront;
            rear = nextRear;
            leftSelected = nextLeftSelected;
          });
        },
      ),
    );
  }
}

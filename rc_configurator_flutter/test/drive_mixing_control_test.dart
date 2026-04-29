import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  testWidgets('rear plus decreases rear ratio only', (tester) async {
    await _pumpDrive(tester, front: 88, rear: 100, leftSelected: false);

    await tester.tap(_plusButton());
    await tester.pump();

    final control = _control(tester);
    expect(control.frontRatio, 88);
    expect(control.rearRatio, 99);
    expect(control.leftSelected, isFalse);
  });

  testWidgets('front minus decreases front ratio only', (tester) async {
    await _pumpDrive(tester, front: 100, rear: 76, leftSelected: true);

    await tester.tap(_minusButton());
    await tester.pump();

    final control = _control(tester);
    expect(control.frontRatio, 99);
    expect(control.rearRatio, 76);
    expect(control.leftSelected, isTrue);
  });

  testWidgets('rear minus at 100 switches to F and immediately changes F', (
    tester,
  ) async {
    await _pumpDrive(tester, front: 72, rear: 100, leftSelected: false);

    await tester.tap(_minusButton());
    await tester.pump();

    final control = _control(tester);
    expect(control.frontRatio, 71);
    expect(control.rearRatio, 100);
    expect(control.leftSelected, isTrue);
  });

  testWidgets('front plus at 100 switches to R and immediately changes R', (
    tester,
  ) async {
    await _pumpDrive(tester, front: 100, rear: 81, leftSelected: true);

    await tester.tap(_plusButton());
    await tester.pump();

    final control = _control(tester);
    expect(control.frontRatio, 100);
    expect(control.rearRatio, 80);
    expect(control.leftSelected, isFalse);
  });

  testWidgets('rear minus at dual 100 switches and immediately changes F', (
    tester,
  ) async {
    await _pumpDrive(tester, front: 100, rear: 100, leftSelected: false);

    await tester.tap(_minusButton());
    await tester.pump();

    final control = _control(tester);
    expect(control.frontRatio, 99);
    expect(control.rearRatio, 100);
    expect(control.leftSelected, isTrue);
  });

  testWidgets('front plus at dual 100 switches and immediately changes R', (
    tester,
  ) async {
    await _pumpDrive(tester, front: 100, rear: 100, leftSelected: true);

    await tester.tap(_plusButton());
    await tester.pump();

    final control = _control(tester);
    expect(control.frontRatio, 100);
    expect(control.rearRatio, 99);
    expect(control.leftSelected, isFalse);
  });
}

DriveMixingControl _control(WidgetTester tester) {
  return tester.widget<DriveMixingControl>(find.byType(DriveMixingControl));
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

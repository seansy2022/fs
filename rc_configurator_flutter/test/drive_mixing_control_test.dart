import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  testWidgets('rear adjusts independently with plus and minus', (tester) async {
    await _pumpDrive(tester, front: 88, rear: 50, leftSelected: false);
    await _tap(tester, _minusButton());
    _expectControl(tester, front: 88, rear: 49, leftSelected: false);
    await _tap(tester, _plusButton());
    _expectControl(tester, front: 88, rear: 50, leftSelected: false);
  });

  testWidgets('front adjusts independently with plus and minus', (tester) async {
    await _pumpDrive(tester, front: 50, rear: 76, leftSelected: true);
    await _tap(tester, _minusButton());
    _expectControl(tester, front: 49, rear: 76, leftSelected: true);
    await _tap(tester, _plusButton());
    _expectControl(tester, front: 50, rear: 76, leftSelected: true);
  });

  testWidgets('rear clamps at both bounds without switching focus', (
    tester,
  ) async {
    await _pumpDrive(tester, front: 72, rear: 0, leftSelected: false);
    await _tap(tester, _minusButton());
    _expectControl(tester, front: 72, rear: 0, leftSelected: false);
    await _tap(tester, _plusButton());
    _expectControl(tester, front: 72, rear: 1, leftSelected: false);
  });

  testWidgets('front clamps at both bounds without switching focus', (
    tester,
  ) async {
    await _pumpDrive(tester, front: 100, rear: 81, leftSelected: true);
    await _tap(tester, _plusButton());
    _expectControl(tester, front: 100, rear: 81, leftSelected: true);
    await _tap(tester, _minusButton());
    _expectControl(tester, front: 99, rear: 81, leftSelected: true);
  });

  testWidgets('tap F and R only changes focus', (tester) async {
    await _pumpDrive(tester, front: 64, rear: 37, leftSelected: true);
    await _tap(tester, find.text('R:37%'));
    _expectControl(tester, front: 64, rear: 37, leftSelected: false);
    await _tap(tester, find.text('F:64%'));
    _expectControl(tester, front: 64, rear: 37, leftSelected: true);
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
}

void _expectControl(
  WidgetTester tester, {
  required int front,
  required int rear,
  required bool leftSelected,
}) {
  final control = _control(tester);
  expect(control.frontRatio, front);
  expect(control.rearRatio, rear);
  expect(control.leftSelected, leftSelected);
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

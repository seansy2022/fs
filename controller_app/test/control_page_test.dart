import 'package:controller_app/src/features/control/view/control_page.dart';
import 'package:controller_app/src/provider/control_presentation_provider.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:controller_app/src/core/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gyro override stays off when control-page gyro switch is off', () {
    expect(
      shouldUseGyroControlOverride(
        gyroEnabled: false,
        gyroMode: GyroMode.directionOnly,
      ),
      isFalse,
    );
    expect(
      shouldUseGyroControlOverride(
        gyroEnabled: false,
        gyroMode: GyroMode.throttleOnly,
      ),
      isFalse,
    );
  });

  test('gyro override only applies for enabled single-axis gyro modes', () {
    expect(
      shouldUseGyroControlOverride(
        gyroEnabled: true,
        gyroMode: GyroMode.directionOnly,
      ),
      isTrue,
    );
    expect(
      shouldUseGyroControlOverride(
        gyroEnabled: true,
        gyroMode: GyroMode.throttleOnly,
      ),
      isTrue,
    );
    expect(
      shouldUseGyroControlOverride(gyroEnabled: true, gyroMode: GyroMode.all),
      isFalse,
    );
  });

  test('turn status follows animation state instead of button state', () {
    expect(isLeftTurnState(ControlAnimationState.forwardLeft), isTrue);
    expect(isLeftTurnState(ControlAnimationState.reverseLeft), isTrue);
    expect(isLeftTurnState(ControlAnimationState.forwardRight), isFalse);
    expect(isRightTurnState(ControlAnimationState.forwardRight), isTrue);
    expect(isRightTurnState(ControlAnimationState.reverseRight), isTrue);
    expect(isRightTurnState(ControlAnimationState.forwardLeft), isFalse);
  });

  testWidgets('gyro direction hint keeps the dot above the up arrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: buildGyroDirectionVerticalAlignmentPreviewForTest(
              upArrow: true,
            ),
          ),
        ),
      ),
    );

    final dotCenter = tester.getCenter(find.byKey(gyroHintDotKey));
    final arrowCenter = tester.getCenter(find.byKey(gyroHintUpArrowKey));

    expect(find.byKey(gyroHintDownArrowKey), findsNothing);
    expect(dotCenter.dy, lessThan(arrowCenter.dy));
  });

  testWidgets('gyro direction hint keeps the dot above the down arrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: buildGyroDirectionVerticalAlignmentPreviewForTest(
              upArrow: false,
            ),
          ),
        ),
      ),
    );

    final dotCenter = tester.getCenter(find.byKey(gyroHintDotKey));
    final arrowCenter = tester.getCenter(find.byKey(gyroHintDownArrowKey));

    expect(find.byKey(gyroHintUpArrowKey), findsNothing);
    expect(dotCenter.dy, lessThan(arrowCenter.dy));
  });

  testWidgets('gyro direction preview no longer reuses the shared Control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: buildGyroDirectionVerticalAlignmentPreviewForTest(
              upArrow: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Control), findsNothing);
  });

  testWidgets('downward gyro preview responds immediately to downward drag', (
    tester,
  ) async {
    double lastValue = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: buildGyroDirectionVerticalAlignmentPreviewForTest(
              upArrow: false,
              onChanged: (value) {
                lastValue = value;
              },
            ),
          ),
        ),
      ),
    );

    final stick = find.byKey(gyroHintStickProbeKey);
    final topCenter = tester.getTopLeft(stick) + const Offset(50, 4);
    final gesture = await tester.startGesture(topCenter);
    await tester.pump();
    final thumbBeforeMove = tester.getRect(find.byKey(gyroHintThumbKey));
    await gesture.moveBy(const Offset(0, 12));
    await tester.pump();
    final thumbAfterMove = tester.getRect(find.byKey(gyroHintThumbKey));

    expect(lastValue, lessThan(0));
    expect(thumbAfterMove.top, greaterThan(thumbBeforeMove.top));

    await gesture.up();
    await tester.pump();
  });

  testWidgets('floating gyro vertical control hides arrow hint while touching', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GyroDirectionalThrottleControl(
              positiveThrottle: true,
              floating: true,
              showArrowHint: true,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(gyroHintUpArrowKey), findsOneWidget);

    final control = find.byType(GyroDirectionalThrottleControl);
    final gesture = await tester.startGesture(tester.getCenter(control));
    await tester.pump();

    expect(find.byKey(gyroHintUpArrowKey), findsNothing);
    expect(find.byKey(floatingControlThumbKey), findsOneWidget);

    await gesture.up();
    await tester.pump();

    expect(find.byKey(gyroHintUpArrowKey), findsOneWidget);
  });

  testWidgets('floating vertical throttle on control page responds to upward drag', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final settings = _TestSettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        controlMode: ControlMode.floating,
        handedness: Handedness.rightThrottle,
        gyroMode: GyroMode.all,
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          appSettingsProvider.overrideWith((ref) => settings),
        ],
        child: const MaterialApp(home: ControlPage()),
      ),
    );
    await tester.pump();

    expect(find.byType(VerticalFloatingControlZone), findsOneWidget);
    expect(find.byType(FloatingControlZone), findsOneWidget);

    final verticalFinder = find.byType(VerticalFloatingControlZone);
    final gesture = await tester.startGesture(tester.getCenter(verticalFinder));
    await tester.pump();

    await gesture.moveBy(const Offset(0, -81));
    await tester.pump();

    expect(repository.lastControlValues, isNotNull);
    expect(repository.lastControlValues!.throttle, lessThan(1500));

    await gesture.up();
    await tester.pump();
  });
}

class _TestSettingsController extends SettingsController {}

class _FakeReceiverRepository implements ReceiverRepository {
  ReceiverControlValues? lastControlValues;

  @override
  ReceiverInfo? get receiverInfo => null;

  @override
  Stream<ReceiverInfo?> get receiverInfoStream => Stream<ReceiverInfo?>.value(null);

  @override
  Stream<ReceiverConnectionState> get connectionStateStream =>
      Stream<ReceiverConnectionState>.value(ReceiverConnectionState.disconnected);

  @override
  Stream<int?> get connectedRssiStream => Stream<int?>.value(null);

  @override
  Stream<List<ReceiverScanDevice>> get scanResultsStream =>
      Stream<List<ReceiverScanDevice>>.value(const <ReceiverScanDevice>[]);

  @override
  Stream<AdapterState> get adapterStateStream =>
      Stream<AdapterState>.value(AdapterState.on);

  @override
  Future<void> updateControlValues(ReceiverControlValues values) async {
    lastControlValues = values;
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> startControlLoop() async {}

  @override
  Future<void> stopControlLoop() async {}

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

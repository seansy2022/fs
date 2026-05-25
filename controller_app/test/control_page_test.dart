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
import 'package:controller_app/src/provider/control_provider.dart';
import 'package:controller_app/src/provider/gyro_prompt_provider.dart';

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

  testWidgets(
    'floating gyro vertical control hides arrow hint while touching',
    (tester) async {
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
    },
  );

  testWidgets(
    'floating vertical throttle on control page responds to upward drag',
    (tester) async {
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
            gyroPromptProvider.overrideWith(
              (ref) => Stream.value(const GyroPrompt.zero()),
            ),
          ],
          child: const MaterialApp(home: ControlPage()),
        ),
      );
      await tester.pump();

      expect(find.byType(VerticalFloatingControlZone), findsOneWidget);
      expect(find.byType(FloatingControlZone), findsOneWidget);

      final verticalFinder = find.byType(VerticalFloatingControlZone);
      final gesture = await tester.startGesture(
        tester.getCenter(verticalFinder),
      );
      await tester.pump();

      await gesture.moveBy(const Offset(0, -81));
      await tester.pump();

      expect(repository.lastControlValues, isNotNull);
      expect(repository.lastControlValues!.throttle, lessThan(1500));

      await gesture.up();
      await tester.pump();
    },
  );

  test('park lock zeros steering throttle and blocks control input', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final settings = _TestSettingsController();
    final container = ProviderContainer(
      overrides: [
        receiverRepositoryProvider.overrideWith((ref) => repository),
        appSettingsProvider.overrideWith((ref) => settings),
        gyroPromptProvider.overrideWith(
          (ref) => Stream.value(const GyroPrompt.zero()),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(controlControllerProvider.notifier);

    await controller.setSteering(0.4);
    await controller.setThrottle(-0.5);
    expect(container.read(controlControllerProvider).steering, 0.4);
    expect(container.read(controlControllerProvider).throttle, -0.5);

    await controller.setParkLocked(true);

    final lockedState = container.read(controlControllerProvider);
    expect(lockedState.parkLocked, isTrue);
    expect(lockedState.steering, 0);
    expect(lockedState.throttle, 0);
    expect(repository.lastControlValues?.steering, 1500);
    expect(repository.lastControlValues?.throttle, 1500);

    await controller.setSteering(-0.8);
    await controller.setThrottle(0.9);

    final unchangedLockedState = container.read(controlControllerProvider);
    expect(unchangedLockedState.steering, 0);
    expect(unchangedLockedState.throttle, 0);

    await controller.toggleGear(true);

    final unlockedState = container.read(controlControllerProvider);
    expect(unlockedState.parkLocked, isFalse);
    expect(unlockedState.highGear, isTrue);
  });

  test('pressAuxChannel toggles CH3 switch output', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final settings = _TestSettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        channels: [
          ...AppSettingsState.defaults().channels.take(2),
          AppSettingsState.defaults().channels[2].copyWith(
            displayName: '辅助1',
            controlType: AuxControlType.switchControl,
            switchValues: const <double>[100, -100],
          ),
          AppSettingsState.defaults().channels[3].copyWith(
            controlType: AuxControlType.disabled,
          ),
        ],
      );
    final container = ProviderContainer(
      overrides: [
        receiverRepositoryProvider.overrideWith((ref) => repository),
        appSettingsProvider.overrideWith((ref) => settings),
        gyroPromptProvider.overrideWith(
          (ref) => Stream.value(const GyroPrompt.zero()),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(controlControllerProvider.notifier);

    await controller.pressAuxChannel(2);
    expect(
      container.read(controlControllerProvider).ch3Runtime.switchOn,
      isTrue,
    );
    expect(repository.lastControlValues?.auxChannels[0], 2000);

    await controller.pressAuxChannel(2);
    expect(
      container.read(controlControllerProvider).ch3Runtime.switchOn,
      isFalse,
    );
    expect(repository.lastControlValues?.auxChannels[0], 1000);
  });

  test('pressAuxChannel cycles CH3 multi-state output', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final settings = _TestSettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        channels: [
          ...AppSettingsState.defaults().channels.take(2),
          AppSettingsState.defaults().channels[2].copyWith(
            displayName: '辅助',
            controlType: AuxControlType.multiState,
            multiStateValues: const <double>[10, 40],
          ),
          AppSettingsState.defaults().channels[3].copyWith(
            controlType: AuxControlType.disabled,
          ),
        ],
      );
    final container = ProviderContainer(
      overrides: [
        receiverRepositoryProvider.overrideWith((ref) => repository),
        appSettingsProvider.overrideWith((ref) => settings),
        gyroPromptProvider.overrideWith(
          (ref) => Stream.value(const GyroPrompt.zero()),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(controlControllerProvider.notifier);

    await controller.pressAuxChannel(2);
    expect(
      container.read(controlControllerProvider).ch3Runtime.selectedIndex,
      1,
    );
    expect(repository.lastControlValues?.auxChannels[0], 1700);

    await controller.pressAuxChannel(2);
    expect(
      container.read(controlControllerProvider).ch3Runtime.selectedIndex,
      0,
    );
    expect(repository.lastControlValues?.auxChannels[0], 1550);
  });

  test('pressAuxChannel sends fixed CH4 value output', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final settings = _TestSettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        channels: [
          ...AppSettingsState.defaults().channels.take(2),
          AppSettingsState.defaults().channels[2].copyWith(
            controlType: AuxControlType.disabled,
          ),
          AppSettingsState.defaults().channels[3].copyWith(
            displayName: '辅助二',
            controlType: AuxControlType.value,
            singleValue: 25,
          ),
        ],
      );
    final container = ProviderContainer(
      overrides: [
        receiverRepositoryProvider.overrideWith((ref) => repository),
        appSettingsProvider.overrideWith((ref) => settings),
        gyroPromptProvider.overrideWith(
          (ref) => Stream.value(const GyroPrompt.zero()),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(controlControllerProvider.notifier);

    await controller.pressAuxChannel(3);

    expect(
      container.read(controlControllerProvider).ch4Runtime.selectedIndex,
      0,
    );
    expect(repository.lastControlValues?.auxChannels[1], 1625);
  });

  testWidgets('value aux button flashes active for a single frame after tap', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final settings = _TestSettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        channels: [
          ...AppSettingsState.defaults().channels.take(2),
          AppSettingsState.defaults().channels[2].copyWith(
            controlType: AuxControlType.disabled,
          ),
          AppSettingsState.defaults().channels[3].copyWith(
            displayName: '辅助二',
            controlType: AuxControlType.value,
            singleValue: 25,
          ),
        ],
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          appSettingsProvider.overrideWith((ref) => settings),
          gyroPromptProvider.overrideWith(
            (ref) => Stream.value(const GyroPrompt.zero()),
          ),
        ],
        child: const MaterialApp(home: ControlPage()),
      ),
    );
    await tester.pump();

    final buttonFinder = find.byKey(
      const ValueKey<String>('control-top-action-ch3'),
    );
    final labelFinder = find.text('辅助二 25%');
    expect(
      tester.widget<Text>(labelFinder).style?.color,
      const Color(0xFF7DA2CE),
    );

    await tester.tap(buttonFinder);
    await tester.pump();

    expect(tester.widget<Text>(labelFinder).style?.color, AppColors.onPrimary);
    expect(repository.lastControlValues?.auxChannels[1], 1625);

    await tester.pump();

    expect(
      tester.widget<Text>(labelFinder).style?.color,
      const Color(0xFF7DA2CE),
    );
  });

  testWidgets(
    'multi-state aux button flashes for a single frame without staying selected',
    (tester) async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final repository = _FakeReceiverRepository();
      final settings = _TestSettingsController()
        ..state = AppSettingsState.defaults().copyWith(
          channels: [
            ...AppSettingsState.defaults().channels.take(2),
            AppSettingsState.defaults().channels[2].copyWith(
              displayName: '辅助',
              controlType: AuxControlType.multiState,
              multiStateValues: const <double>[10, 40],
            ),
            AppSettingsState.defaults().channels[3].copyWith(
              controlType: AuxControlType.disabled,
            ),
          ],
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            receiverRepositoryProvider.overrideWith((ref) => repository),
            appSettingsProvider.overrideWith((ref) => settings),
            gyroPromptProvider.overrideWith(
              (ref) => Stream.value(const GyroPrompt.zero()),
            ),
          ],
          child: const MaterialApp(home: ControlPage()),
        ),
      );
      await tester.pump();

      final buttonFinder = find.byKey(
        const ValueKey<String>('control-top-action-ch2-state-1'),
      );
      final labelFinder = find.text('辅助 状态2');
      expect(
        tester.widget<Text>(labelFinder).style?.color,
        const Color(0xFF7DA2CE),
      );

      await tester.tap(buttonFinder);
      await tester.pump();

      expect(
        tester.widget<Text>(labelFinder).style?.color,
        AppColors.onPrimary,
      );
      expect(repository.lastControlValues?.auxChannels[0], 1700);

      await tester.pump();

      expect(
        tester.widget<Text>(labelFinder).style?.color,
        const Color(0xFF7DA2CE),
      );
    },
  );

  testWidgets('control page keeps CH3 and CH4 aux buttons on one row at left', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final settings = _TestSettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        channels: [
          ...AppSettingsState.defaults().channels.take(2),
          AppSettingsState.defaults().channels[2].copyWith(
            displayName: '辅助',
            controlType: AuxControlType.multiState,
            multiStateValues: const <double>[10, 40],
          ),
          AppSettingsState.defaults().channels[3].copyWith(
            displayName: '辅助二',
            controlType: AuxControlType.value,
            singleValue: 0,
          ),
        ],
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          appSettingsProvider.overrideWith((ref) => settings),
          gyroPromptProvider.overrideWith(
            (ref) => Stream.value(const GyroPrompt.zero()),
          ),
        ],
        child: const MaterialApp(home: ControlPage()),
      ),
    );
    await tester.pump();

    expect(find.text('辅助 状态1'), findsOneWidget);
    expect(find.text('辅助 状态2'), findsOneWidget);
    expect(find.text('辅助二 0%'), findsOneWidget);
    final ch3Top = tester.getTopLeft(
      find.byKey(const ValueKey<String>('control-top-action-ch2-state-0')),
    );
    final ch3State2Top = tester.getTopLeft(
      find.byKey(const ValueKey<String>('control-top-action-ch2-state-1')),
    );
    final ch4Top = tester.getTopLeft(
      find.byKey(const ValueKey<String>('control-top-action-ch3')),
    );
    final driveSwitchTop = tester.getTopLeft(find.byType(RcDriveModeSwitch));
    final ch3Center = tester.getCenter(
      find.byKey(const ValueKey<String>('control-top-action-ch2-state-0')),
    );
    final driveSwitchCenter = tester.getCenter(find.byType(RcDriveModeSwitch));

    expect(ch3Top.dy, ch3State2Top.dy);
    expect(ch4Top.dy, ch3Top.dy);
    expect((ch3Center.dy - driveSwitchCenter.dy).abs(), lessThanOrEqualTo(10));
    expect(ch3Top.dx, lessThan(driveSwitchTop.dx));
    expect(ch3State2Top.dx, greaterThan(ch3Top.dx));
    expect(ch4Top.dx, lessThan(driveSwitchTop.dx));
  });
}

class _TestSettingsController extends SettingsController {}

class _FakeReceiverRepository implements ReceiverRepository {
  ReceiverControlValues? lastControlValues;

  @override
  ReceiverInfo? get receiverInfo => null;

  @override
  Stream<ReceiverInfo?> get receiverInfoStream =>
      Stream<ReceiverInfo?>.value(null);

  @override
  Stream<ReceiverConnectionState> get connectionStateStream =>
      Stream<ReceiverConnectionState>.value(
        ReceiverConnectionState.disconnected,
      );

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

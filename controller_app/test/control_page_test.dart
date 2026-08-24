import 'dart:async';

import 'package:controller_app/src/features/control/controllers/control_controller.dart';
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

  test('multi-state controls display configured state labels', () {
    final channel = AppSettingsState.defaults().channels[2].copyWith(
      controlType: AuxControlType.multiState,
      multiStateValues: const <double>[-100, 0, 100],
      multiStateLabels: const <String>['低速', '中速', '高速'],
    );
    const runtime = AuxChannelRuntimeState(
      controlType: AuxControlType.multiState,
      selectedIndex: 1,
    );

    expect(auxChannelControlLabels(channel, runtime), <String>[
      '低速',
      '中速',
      '高速',
    ]);
    expect(auxChannelControlLabel(channel, runtime), '辅助1 中速');
  });

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

  test('gyro override applies for every enabled non-closed gyro mode', () {
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
      isTrue,
    );
    expect(
      shouldUseGyroControlOverride(gyroEnabled: true, gyroMode: GyroMode.off),
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

  testWidgets('方向加油门体感隐藏主控并固定两条微调的位置', (tester) async {
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

    final steeringTrim = find.byKey(
      const ValueKey<String>('control-steering-trim'),
    );
    final throttleTrim = find.byKey(
      const ValueKey<String>('control-throttle-trim'),
    );
    expect(find.byType(VerticalFloatingControlZone), findsNothing);
    expect(find.byType(FloatingControlZone), findsNothing);
    expect(steeringTrim, findsOneWidget);
    expect(throttleTrim, findsOneWidget);
    expect(
      tester.getCenter(steeringTrim).dx,
      lessThan(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
      ),
    );
    expect(
      tester.getCenter(throttleTrim).dx,
      greaterThan(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
      ),
    );
  });

  testWidgets('油门体感保留方向主控并固定两条微调的位置', (tester) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final settings = _TestSettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        controlMode: ControlMode.fixedPosition,
        handedness: Handedness.rightThrottle,
        gyroMode: GyroMode.throttleOnly,
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ControlPage()),
      ),
    );
    await tester.pump();

    await container
        .read(controlControllerProvider.notifier)
        .setGyroEnabled(true);
    await tester.pump();

    final horizontalControls = find.byWidgetPredicate(
      (widget) =>
          widget is Control &&
          widget.direction == ControlSliderDirection.horizontal,
    );
    final verticalControls = find.byWidgetPredicate(
      (widget) =>
          widget is Control &&
          widget.direction == ControlSliderDirection.vertical,
    );
    final horizontalSliders = find.byWidgetPredicate(
      (widget) =>
          widget is RCControllSider &&
          widget.direction == RCControllSiderDirection.horizontal,
    );
    final verticalSliders = find.byWidgetPredicate(
      (widget) =>
          widget is RCControllSider &&
          widget.direction == RCControllSiderDirection.vertical,
    );

    expect(horizontalControls, findsOneWidget);
    expect(verticalControls, findsNothing);
    expect(horizontalSliders, findsOneWidget);
    expect(verticalSliders, findsOneWidget);
    expect(
      tester.getCenter(horizontalControls).dx,
      lessThan(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
      ),
    );
    expect(
      tester.getCenter(horizontalSliders).dx,
      lessThan(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
      ),
    );
    expect(
      tester.getCenter(verticalSliders).dx,
      greaterThan(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
      ),
    );
  });

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

  test('activate pushes base values before starting control loop', () async {
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

    await controller.activate();

    expect(repository.callOrder, <String>[
      'updateControlValues',
      'startControlLoop',
    ]);
    expect(repository.lastControlValues?.auxChannels, <int>[
      1000,
      1000,
      0,
      0,
      0,
      0,
      0,
      0,
    ]);
  });

  test('suspended control output stops all receiver writes', () async {
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

    await controller.activate();
    await controller.suspendControlOutput();
    await controller.setThrottle(1);
    await controller.setGyroPrompt(steering: 1, throttle: 1);

    expect(repository.callOrder, <String>[
      'updateControlValues',
      'startControlLoop',
      'stopControlLoop',
    ]);
  });

  testWidgets('control page starts the loop after countdown and connection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final connectionStates = StreamController<ReceiverConnectionState>();
    addTearDown(connectionStates.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          receiverConnectionProvider.overrideWith(
            (ref) => connectionStates.stream,
          ),
          appSettingsProvider.overrideWith((ref) => _TestSettingsController()),
          gyroPromptProvider.overrideWith(
            (ref) => Stream.value(const GyroPrompt.zero()),
          ),
        ],
        child: const MaterialApp(home: ControlPage()),
      ),
    );
    connectionStates.add(ReceiverConnectionState.disconnected);
    await tester.pump();

    connectionStates.add(ReceiverConnectionState.connected);
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('control-countdown')),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);
    expect(repository.callOrder, isEmpty);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    expect(repository.callOrder, isEmpty);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);
    expect(repository.callOrder, isEmpty);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('control-countdown')),
      findsNothing,
    );
    expect(repository.callOrder, <String>[
      'updateControlValues',
      'startControlLoop',
    ]);
  });

  testWidgets('control page stops sending when app enters background', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final connectionStates = StreamController<ReceiverConnectionState>();
    addTearDown(connectionStates.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          receiverConnectionProvider.overrideWith(
            (ref) => connectionStates.stream,
          ),
          appSettingsProvider.overrideWith((ref) => _TestSettingsController()),
          gyroPromptProvider.overrideWith(
            (ref) => Stream.value(const GyroPrompt.zero()),
          ),
        ],
        child: const MaterialApp(home: ControlPage()),
      ),
    );
    connectionStates.add(ReceiverConnectionState.connected);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(repository.callOrder, contains('startControlLoop'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(repository.callOrder.last, 'stopControlLoop');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(
      repository.callOrder.where((call) => call == 'startControlLoop'),
      hasLength(2),
    );
  });

  testWidgets('control page stops sending when it is removed', (tester) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final connectionStates = StreamController<ReceiverConnectionState>();
    addTearDown(connectionStates.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          receiverConnectionProvider.overrideWith(
            (ref) => connectionStates.stream,
          ),
          appSettingsProvider.overrideWith((ref) => _TestSettingsController()),
          gyroPromptProvider.overrideWith(
            (ref) => Stream.value(const GyroPrompt.zero()),
          ),
        ],
        child: const MaterialApp(home: ControlPage()),
      ),
    );
    connectionStates.add(ReceiverConnectionState.connected);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(repository.callOrder, contains('startControlLoop'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(repository.callOrder.last, 'stopControlLoop');
  });

  test(
    'low gear halves forward throttle output while high gear keeps full',
    () async {
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

      await controller.setThrottle(1);
      expect(container.read(controlControllerProvider).throttle, 0.5);
      expect(repository.lastControlValues?.throttle, 1750);

      await controller.toggleGear(true);
      expect(container.read(controlControllerProvider).throttle, 1);
      expect(repository.lastControlValues?.throttle, 2000);
    },
  );

  test('low gear does not affect reverse throttle output', () async {
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

    await controller.setThrottle(-1);

    expect(container.read(controlControllerProvider).throttle, -1);
    expect(repository.lastControlValues?.throttle, 1000);
  });

  test('CH2 uses configured low high center mapping for steering', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final defaults = AppSettingsState.defaults();
    final settings = _TestSettingsController()
      ..state = defaults.copyWith(
        channels: [
          defaults.channels.first,
          defaults.channels[1].copyWith(
            lowPercent: -50,
            highPercent: 50,
            trimPercent: 1,
          ),
          ...defaults.channels.skip(2),
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

    await controller.setSteering(-1);
    expect(repository.lastControlValues?.steering, 1250);

    await controller.setSteering(0);
    expect(repository.lastControlValues?.steering, 1505);

    await controller.setSteering(0.5);
    expect(repository.lastControlValues?.steering, 1628);
  });

  test(
    'CH1 uses configured mapping while preserving forward reverse direction',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final repository = _FakeReceiverRepository();
      final defaults = AppSettingsState.defaults();
      final settings = _TestSettingsController()
        ..state = defaults.copyWith(
          channels: [
            defaults.channels.first.copyWith(
              lowPercent: -50,
              highPercent: 80,
              trimPercent: -1,
            ),
            defaults.channels[1],
            ...defaults.channels.skip(2),
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

      await controller.setThrottle(1);
      expect(repository.lastControlValues?.throttle, 1698);

      await controller.toggleGear(true);
      expect(repository.lastControlValues?.throttle, 1900);

      await controller.setThrottle(0);
      expect(repository.lastControlValues?.throttle, 1495);

      await controller.setThrottle(-1);
      expect(repository.lastControlValues?.throttle, 1250);
    },
  );

  test('CH2 trim applies after configured channel center mapping', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final defaults = AppSettingsState.defaults();
    final settings = _TestSettingsController()
      ..state = defaults.copyWith(
        channels: [
          defaults.channels.first,
          defaults.channels[1].copyWith(trimPercent: 10),
          ...defaults.channels.skip(2),
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

    await controller.setSteering(0);
    expect(repository.lastControlValues?.steering, 1510);

    await controller.adjustTrim(2);
    expect(repository.lastControlValues?.steering, 1514);

    await controller.setThrottleTrim(-3);
    expect(repository.lastControlValues?.throttle, 1494);
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
    expect(repository.lastPulseChannelIndex, isNull);
    expect(repository.lastControlValues?.auxChannels[0], 2000);

    await controller.pressAuxChannel(2);
    expect(
      container.read(controlControllerProvider).ch3Runtime.switchOn,
      isFalse,
    );
    expect(repository.lastPulseChannelIndex, isNull);
    expect(repository.lastControlValues?.auxChannels[0], 1000);
  });

  test('pressAuxChannel persists CH3 switch selection', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final stateForTest = AppSettingsState.defaults().copyWith(
      channels: [
        ...AppSettingsState.defaults().channels.take(2),
        AppSettingsState.defaults().channels[2].copyWith(
          controlType: AuxControlType.switchControl,
        ),
        AppSettingsState.defaults().channels[3].copyWith(
          controlType: AuxControlType.disabled,
        ),
      ],
    );
    final firstSettings = await _settingsControllerWith(stateForTest);
    final firstContainer = ProviderContainer(
      overrides: [
        receiverRepositoryProvider.overrideWith((ref) => repository),
        appSettingsProvider.overrideWith((ref) => firstSettings),
        gyroPromptProvider.overrideWith(
          (ref) => Stream.value(const GyroPrompt.zero()),
        ),
      ],
    );
    final firstSub = firstContainer.listen(
      controlControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    final firstController = firstContainer.read(
      controlControllerProvider.notifier,
    );

    await firstController.pressAuxChannel(2);
    await Future<void>.delayed(Duration.zero);
    firstSub.close();
    firstContainer.dispose();

    final secondSettings = await _settingsControllerWith(stateForTest);
    final secondContainer = ProviderContainer(
      overrides: [
        receiverRepositoryProvider.overrideWith((ref) => repository),
        appSettingsProvider.overrideWith((ref) => secondSettings),
        gyroPromptProvider.overrideWith(
          (ref) => Stream.value(const GyroPrompt.zero()),
        ),
      ],
    );
    final secondSub = secondContainer.listen(
      controlControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(secondSub.close);
    addTearDown(secondContainer.dispose);
    secondContainer.read(controlControllerProvider.notifier);
    await _waitForAuxRuntimeLoad();

    expect(
      secondContainer.read(controlControllerProvider).ch3Runtime.switchOn,
      isTrue,
    );
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
    expect(repository.lastPulseChannelIndex, isNull);
    expect(repository.lastControlValues?.auxChannels[0], 1700);

    await controller.pressAuxChannel(2);
    expect(
      container.read(controlControllerProvider).ch3Runtime.selectedIndex,
      0,
    );
    expect(repository.lastPulseChannelIndex, isNull);
    expect(repository.lastControlValues?.auxChannels[0], 1550);
  });

  test('pressAuxChannel persists CH3 multi-state selection', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final stateForTest = AppSettingsState.defaults().copyWith(
      channels: [
        ...AppSettingsState.defaults().channels.take(2),
        AppSettingsState.defaults().channels[2].copyWith(
          controlType: AuxControlType.multiState,
          multiStateValues: const <double>[-100, 0, 100],
        ),
        AppSettingsState.defaults().channels[3].copyWith(
          controlType: AuxControlType.disabled,
        ),
      ],
    );
    final firstSettings = await _settingsControllerWith(stateForTest);
    final firstContainer = ProviderContainer(
      overrides: [
        receiverRepositoryProvider.overrideWith((ref) => repository),
        appSettingsProvider.overrideWith((ref) => firstSettings),
        gyroPromptProvider.overrideWith(
          (ref) => Stream.value(const GyroPrompt.zero()),
        ),
      ],
    );
    final firstSub = firstContainer.listen(
      controlControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    final firstController = firstContainer.read(
      controlControllerProvider.notifier,
    );

    await firstController.pressAuxChannel(2, selectedIndex: 2);
    await Future<void>.delayed(Duration.zero);
    firstSub.close();
    firstContainer.dispose();

    final secondSettings = await _settingsControllerWith(stateForTest);
    final secondContainer = ProviderContainer(
      overrides: [
        receiverRepositoryProvider.overrideWith((ref) => repository),
        appSettingsProvider.overrideWith((ref) => secondSettings),
        gyroPromptProvider.overrideWith(
          (ref) => Stream.value(const GyroPrompt.zero()),
        ),
      ],
    );
    final secondSub = secondContainer.listen(
      controlControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(secondSub.close);
    addTearDown(secondContainer.dispose);
    secondContainer.read(controlControllerProvider.notifier);
    await _waitForAuxRuntimeLoad();

    expect(
      secondContainer.read(controlControllerProvider).ch3Runtime.selectedIndex,
      2,
    );
  });

  test('pressAuxChannel sends extended CH3 multi-state output', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final settings = _TestSettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        channels: [
          ...AppSettingsState.defaults().channels.take(2),
          AppSettingsState.defaults().channels[2].copyWith(
            displayName: '辅助',
            controlType: AuxControlType.multiState,
            multiStateValues: const <double>[-120, 0, 120],
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

    await controller.pressAuxChannel(2, selectedIndex: 2);

    expect(repository.lastPulseChannelIndex, isNull);
    expect(repository.lastControlValues?.auxChannels[0], 2100);
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
    expect(repository.lastPulseChannelIndex, isNull);
    expect(repository.lastControlValues?.auxChannels[1], 1625);
  });

  test(
    'base CH3 and CH4 values come from channel settings while CH5-CH10 stay zero',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final repository = _FakeReceiverRepository();
      final settings = _TestSettingsController()
        ..state = AppSettingsState.defaults().copyWith(
          channels: [
            ...AppSettingsState.defaults().channels.take(2),
            AppSettingsState.defaults().channels[2].copyWith(
              controlType: AuxControlType.switchControl,
              switchValues: const <double>[100, -100],
            ),
            AppSettingsState.defaults().channels[3].copyWith(
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

      await controller.setThrottle(0.1);

      expect(repository.lastControlValues?.auxChannels[0], 1000);
      expect(repository.lastControlValues?.auxChannels[1], 1625);
      expect(
        repository.lastControlValues?.auxChannels.sublist(2),
        everyElement(0),
      );
    },
  );

  testWidgets('value aux button stays selected on control page', (
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
    expect(tester.widget<Text>(labelFinder).style?.color, AppColors.onPrimary);

    await tester.tap(buttonFinder);
    await tester.pump();

    expect(tester.widget<Text>(labelFinder).style?.color, AppColors.onPrimary);
    expect(repository.lastPulseChannelIndex, isNull);
    expect(repository.lastControlValues?.auxChannels[1], 1625);

    await tester.pump();

    expect(tester.widget<Text>(labelFinder).style?.color, AppColors.onPrimary);
  });

  testWidgets('multi-state aux button cycles selected state', (tester) async {
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
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    final buttonFinder = find.byKey(
      const ValueKey<String>('control-top-action-ch2'),
    );
    expect(find.text('辅助'), findsOneWidget);
    expect(
      find.descendant(of: buttonFinder, matching: find.text('状态 1')),
      findsOneWidget,
    );

    await tester.tap(buttonFinder);
    await tester.pump();

    expect(
      find.descendant(of: buttonFinder, matching: find.text('状态 2')),
      findsOneWidget,
    );
    expect(repository.lastPulseChannelIndex, isNull);
    expect(repository.lastControlValues?.auxChannels[0], 1700);

    await tester.tap(buttonFinder);
    await tester.pump();

    expect(
      find.descendant(of: buttonFinder, matching: find.text('状态 1')),
      findsOneWidget,
    );
  });

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
            multiStateValues: const <double>[10, 20, 30, 40, 50],
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

    expect(find.text('辅助'), findsOneWidget);
    expect(find.text('状态 1'), findsOneWidget);
    expect(find.text('状态 2'), findsOneWidget);
    expect(find.text('自定义名称'), findsOneWidget);
    expect(find.text('辅助二 0%'), findsOneWidget);
    final ch3LabelTop = tester.getTopLeft(
      find.byKey(const ValueKey<String>('control-top-action-ch2-label')),
    );
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

    expect(ch3LabelTop.dy, ch3Top.dy);
    expect(ch3Top.dy, ch3State2Top.dy);
    expect(ch4Top.dy, ch3Top.dy);
    expect((ch3Center.dy - driveSwitchCenter.dy).abs(), lessThanOrEqualTo(10));
    expect(ch3Top.dx, lessThan(driveSwitchTop.dx));
    expect(ch3State2Top.dx, greaterThan(ch3Top.dx));
    expect(ch4Top.dx, lessThan(driveSwitchTop.dx));
  });

  testWidgets('slider stays inactive until trim toggle is enabled', (
    tester,
  ) async {
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
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ControlPage()),
      ),
    );
    await tester.pump();

    final sliderFinder = find.byType(RCControllSider).first;
    expect(tester.widget<RCControllSider>(sliderFinder).enabled, isFalse);

    container.read(controlControllerProvider.notifier).toggleSliderButtons();
    await tester.pump();

    expect(tester.widget<RCControllSider>(sliderFinder).enabled, isTrue);
  });
}

class _TestSettingsController extends SettingsController {}

Future<_TestSettingsController> _settingsControllerWith(
  AppSettingsState state,
) async {
  final controller = _TestSettingsController();
  await Future<void>.delayed(Duration.zero);
  controller.state = state;
  return controller;
}

Future<void> _waitForAuxRuntimeLoad() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

class _FakeReceiverRepository implements ReceiverRepository {
  final List<String> callOrder = <String>[];
  ReceiverControlValues? lastControlValues;
  int? lastPulseChannelIndex;
  int? lastPulseValue;

  @override
  ReceiverConnectionState get connectionState =>
      ReceiverConnectionState.connected;

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
    callOrder.add('updateControlValues');
    lastControlValues = values;
  }

  @override
  Future<void> queueAuxChannelPulse(int auxChannelIndex, int value) async {
    lastPulseChannelIndex = auxChannelIndex;
    lastPulseValue = value;
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> startControlLoop() async {
    callOrder.add('startControlLoop');
  }

  @override
  Future<void> stopControlLoop() async {
    callOrder.add('stopControlLoop');
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

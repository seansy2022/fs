import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_provider.dart';
import 'package:rc_configurator_flutter/src/provider/control_mapping_provider.dart';
import 'package:rc_configurator_flutter/src/provider/curve_provider.dart';
import 'package:rc_configurator_flutter/src/provider/dashboard_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'button_trigger_flow_test_utils.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('debounce button triggers stay isolated by feature', () async {
    final env = await connectTestEnv();
    addTearDown(() async => disposeTestEnv(env));
    final app = env.container.read(rcAppStateProvider);
    final ch = app.channels.first.copyWith(dualRate: 77, lLimit: 66);

    await expectSentCommands(
      env,
      () => env.notifier.dispatch(DualRateUpdatedIntent(id: ch.id, next: ch)),
      [BluetoothCommand.dualRate],
      debounced: true,
    );
    await expectSentCommands(
      env,
      () => env.container.read(curveProvider.notifier).updateCurveValue(21),
      [BluetoothCommand.curve],
      debounced: true,
    );
    await expectSentCommands(
      env,
      () =>
          env.container.read(controlMappingProvider.notifier).updateAction('无'),
      [BluetoothCommand.controlMapping],
      debounced: true,
    );
    await expectSentCommands(
      env,
      () => env.container
          .read(dashboardProvider.notifier)
          .updateRadioSettings(app.radioSettings.copyWith(idleAlarm: 60)),
      [BluetoothCommand.systemSetting],
      debounced: true,
    );
    await expectSentCommands(
      env,
      () => env.container
          .read(dashboardProvider.notifier)
          .updateMixingSettings(
            app.mixingSettings.copyWith(
              activeMode: '4WS',
              selectedChannel: 'CH1',
            ),
          ),
      [BluetoothCommand.fourWheelSteer],
      debounced: true,
    );
    await expectSentCommands(
      env,
      () => env.container
          .read(dashboardProvider.notifier)
          .updateChannel(ch.id, ch),
      [
        BluetoothCommand.channelReverse,
        BluetoothCommand.channelTravel,
        BluetoothCommand.subTrim,
        BluetoothCommand.dualRate,
        BluetoothCommand.failsafe,
      ],
      debounced: true,
    );
  });
}

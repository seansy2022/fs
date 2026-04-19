import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/provider/curve_provider.dart';
import 'package:rc_configurator_flutter/src/provider/dashboard_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'button_trigger_flow_test_utils.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('non-debounce button triggers send expected commands', () async {
    final env = await connectTestEnv();
    addTearDown(() async => disposeTestEnv(env));

    await expectSentCommands(
      env,
      () => env.container.read(dashboardProvider.notifier).selectModel('MOD01'),
      [BluetoothCommand.modelSwitch],
      debounced: false,
    );
    await expectSentCommands(
      env,
      () => env.container.read(curveProvider.notifier).selectCurve('Brake'),
      [BluetoothCommand.curve],
      debounced: false,
    );
    await expectSentCommands(
      env,
      () => env.container
          .read(dashboardProvider.notifier)
          .renameModel('MOD01', 'A'),
      const [],
      debounced: false,
    );
  });
}

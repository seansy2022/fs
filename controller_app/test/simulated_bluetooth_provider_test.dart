import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/core/receiver_battery_status.dart';
import 'package:controller_app/src/provider/app_settings_provider.dart';
import 'package:controller_app/src/provider/simulated_bluetooth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('simulated voltage uses the receiver fixed calibration', () {
    final status = ReceiverBatteryStatus.fromRawBatteryLevel(
      rawBatteryLevel: 75,
      minimumVoltage: 6.0,
      fullVoltage: 8.4,
    );

    expect(status.voltage, closeTo(7.25, 0.0001));
  });

  test('simulated telemetry cycles full to empty then reconnects', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final settings = SettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        minimumVoltage: 6.0,
        fullVoltage: 8.4,
      );
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith((ref) => settings),
        simulatedBluetoothEnabledProvider.overrideWith((ref) => true),
        simulatedBluetoothStepDurationProvider.overrideWith((ref) {
          return const Duration(milliseconds: 10);
        }),
      ],
    );
    addTearDown(container.dispose);

    final states = <SimulatedBluetoothSnapshot>[];
    final subscription = container.listen(simulatedBluetoothTelemetryProvider, (
      _,
      next,
    ) {
      if (next != null) {
        states.add(next);
      }
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await Future<void>.delayed(const Duration(milliseconds: 95));

    expect(
      states.any(
        (state) =>
            state.connectionState == ReceiverConnectionState.connected &&
            state.batteryLevel == 100 &&
            state.rssi == -40,
      ),
      isTrue,
    );
    expect(
      states.any(
        (state) =>
            state.connectionState == ReceiverConnectionState.connected &&
            state.batteryLevel == 75 &&
            state.rssi == -60,
      ),
      isTrue,
    );
    expect(
      states.any(
        (state) =>
            state.connectionState == ReceiverConnectionState.connected &&
            state.batteryLevel == 50 &&
            state.rssi == -75,
      ),
      isTrue,
    );
    expect(
      states.any(
        (state) =>
            state.connectionState == ReceiverConnectionState.connected &&
            state.batteryLevel == 25 &&
            state.rssi == -90,
      ),
      isTrue,
    );
    expect(
      states.any(
        (state) =>
            state.connectionState == ReceiverConnectionState.connected &&
            state.batteryLevel == 0 &&
            state.rssi == -90,
      ),
      isTrue,
    );
    expect(
      states.any(
        (state) =>
            state.connectionState == ReceiverConnectionState.disconnected &&
            state.voltage == null,
      ),
      isTrue,
    );
    expect(
      states
              .where(
                (state) =>
                    state.connectionState ==
                        ReceiverConnectionState.connected &&
                    state.batteryLevel == 100 &&
                    state.rssi == -40,
              )
              .length >=
          2,
      isTrue,
    );
  });
}

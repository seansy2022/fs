import 'dart:typed_data';

import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/provider/alert_message_provider.dart';
import 'package:controller_app/src/provider/app_settings_provider.dart';
import 'package:controller_app/src/provider/effective_bluetooth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('control page message ignores alarm switches and uses thresholds', () {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final settings = SettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        lowVoltageEnabled: false,
        batteryAlertPercent: 30,
        lowSignalEnabled: false,
        signalThreshold: 80,
      );
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith((ref) => settings),
        appSettingsLoadedProvider.overrideWith((ref) => true),
        effectiveReceiverInfoProvider.overrideWith((ref) {
          return ReceiverInfo(
            rfmId: Uint8List(4),
            productModelCode: 1,
            batteryLevel: 20,
          );
        }),
        effectiveReceiverConnectionProvider.overrideWith((ref) {
          return ReceiverConnectionState.connected;
        }),
        effectiveConnectedRssiProvider.overrideWith((ref) => -90),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(controlPageAlertMessageProvider), '电量低！ 信号低！');
  });

  test('control page message shows only active warning', () {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final settings = SettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        batteryAlertPercent: 10,
        signalThreshold: 80,
      );
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith((ref) => settings),
        appSettingsLoadedProvider.overrideWith((ref) => true),
        effectiveReceiverInfoProvider.overrideWith((ref) {
          return ReceiverInfo(
            rfmId: Uint8List(4),
            productModelCode: 1,
            batteryLevel: 80,
          );
        }),
        effectiveReceiverConnectionProvider.overrideWith((ref) {
          return ReceiverConnectionState.connected;
        }),
        effectiveConnectedRssiProvider.overrideWith((ref) => -90),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(controlPageAlertMessageProvider), '信号低！');
  });
}

import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('settings controller updates battery defaults for 3S', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = SettingsController();

    await Future<void>.delayed(Duration.zero);
    controller.updateBatterySettings(batteryType: BatteryType.threeCell);

    expect(controller.state.batteryType, BatteryType.threeCell);
    expect(controller.state.minimumVoltage, 9.3);
    expect(controller.state.fullVoltage, 12.6);
  });

  test('settings controller switches handedness', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = SettingsController();

    await Future<void>.delayed(Duration.zero);
    controller.setHandedness(Handedness.leftThrottle);

    expect(controller.state.handedness, Handedness.leftThrottle);
  });
}

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
    expect(controller.state.minimumVoltage, 9.0);
    expect(controller.state.fullVoltage, 12.6);
  });

  test('settings controller updates battery defaults for 4S', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = SettingsController();

    await Future<void>.delayed(Duration.zero);
    controller.updateBatterySettings(batteryType: BatteryType.fourCell);

    expect(controller.state.batteryType, BatteryType.fourCell);
    expect(controller.state.minimumVoltage, 12.0);
    expect(controller.state.fullVoltage, 16.8);
  });

  test('settings controller updates battery defaults for 1S', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = SettingsController();

    await Future<void>.delayed(Duration.zero);
    controller.updateBatterySettings(batteryType: BatteryType.oneCell);

    expect(controller.state.batteryType, BatteryType.oneCell);
    expect(controller.state.minimumVoltage, 3.0);
    expect(controller.state.fullVoltage, 4.2);
  });

  test('settings controller updates battery defaults for other', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = SettingsController();

    await Future<void>.delayed(Duration.zero);
    controller.updateBatterySettings(batteryType: BatteryType.other);

    expect(controller.state.batteryType, BatteryType.other);
    expect(controller.state.minimumVoltage, 6.0);
    expect(controller.state.fullVoltage, 8.4);
  });

  test('settings controller maps legacy custom battery type to other', () {
    final state = AppSettingsState.fromJson(const <String, Object?>{
      'handedness': 'rightThrottle',
      'controlMode': 'fixedPosition',
      'gyroMode': 'off',
      'channels': <Object?>[],
      'trackMixLeft': 100,
      'trackMixRight': 100,
      'lowVoltageEnabled': true,
      'batteryType': 'custom',
      'minimumVoltage': 6.0,
      'fullVoltage': 8.4,
      'batteryAlertPercent': 15,
      'batteryVoice': true,
      'batteryVibration': true,
      'lowSignalEnabled': true,
      'signalThreshold': 30,
      'signalVoice': true,
      'signalVibration': false,
      'reconnectVoice': true,
      'reconnectVibration': false,
      'backgroundMusicMode': 'defaultTrack',
      'backgroundMusicName': '默认背景音乐',
    });

    expect(state.batteryType, BatteryType.other);
  });

  test('settings controller switches handedness', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = SettingsController();

    await Future<void>.delayed(Duration.zero);
    controller.setHandedness(Handedness.leftThrottle);

    expect(controller.state.handedness, Handedness.leftThrottle);
  });

  test('legacy auxiliary functions map to new aux control types', () {
    final state = AppSettingsState.fromJson(const <String, Object?>{
      'handedness': 'rightThrottle',
      'controlMode': 'fixedPosition',
      'gyroMode': 'throttleOnly',
      'channels': <Object?>[
        <String, Object?>{
          'channelLabel': 'CH1',
          'title': '方向',
          'function': 'none',
          'lowPercent': -100,
          'highPercent': 100,
          'trimPercent': 0,
          'reversed': false,
        },
        <String, Object?>{
          'channelLabel': 'CH2',
          'title': '油门',
          'function': 'none',
          'lowPercent': -100,
          'highPercent': 100,
          'trimPercent': 0,
          'reversed': false,
        },
        <String, Object?>{
          'channelLabel': 'CH3',
          'title': '辅助通道',
          'function': 'gearControl',
          'lowPercent': -100,
          'highPercent': 100,
          'trimPercent': 33,
          'reversed': false,
        },
        <String, Object?>{
          'channelLabel': 'CH4',
          'title': '辅助通道',
          'function': 'gyro',
          'lowPercent': -20,
          'highPercent': 80,
          'trimPercent': 25,
          'reversed': false,
        },
      ],
      'trackMixLeft': 100,
      'trackMixRight': 100,
      'lowVoltageEnabled': true,
      'batteryType': 'twoCell',
      'minimumVoltage': 6.0,
      'fullVoltage': 8.4,
      'batteryAlertPercent': 15,
      'batteryVoice': true,
      'batteryVibration': true,
      'lowSignalEnabled': true,
      'signalThreshold': 30,
      'signalVoice': true,
      'signalVibration': false,
      'reconnectVoice': true,
      'reconnectVibration': false,
      'backgroundMusicMode': 'defaultTrack',
      'backgroundMusicName': '默认背景音乐',
    });

    expect(state.channels[2].controlType, AuxControlType.multiState);
    expect(state.channels[2].displayName, '辅助1');
    expect(state.channels[3].controlType, AuxControlType.value);
    expect(state.channels[3].singleValue, 25);
  });
}

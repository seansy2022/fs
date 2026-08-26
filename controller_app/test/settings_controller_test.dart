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
    expect(state.gyroMode, GyroMode.throttleOnly);
    expect(state.gyroHandMode, GyroHandMode.left);
  });

  test('settings controller switches handedness', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = SettingsController();

    await Future<void>.delayed(Duration.zero);
    controller.setHandedness(Handedness.leftThrottle);

    expect(controller.state.handedness, Handedness.leftThrottle);
  });

  test('settings controller persists gyro hand mode independently', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = SettingsController();

    await Future<void>.delayed(Duration.zero);
    controller.setGyroHandMode(GyroHandMode.dual);
    final restored = AppSettingsState.fromStorageString(
      controller.state.toStorageString(),
    );

    expect(restored.gyroMode, GyroMode.throttleOnly);
    expect(restored.gyroHandMode, GyroHandMode.dual);
  });

  test('settings controller persists single hand mode', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = SettingsController();

    await Future<void>.delayed(Duration.zero);
    controller.setHandedness(Handedness.singleRight);
    final restored = AppSettingsState.fromStorageString(
      controller.state.toStorageString(),
    );

    expect(restored.handedness, Handedness.singleRight);
  });

  test('settings controller persists tank mixing enabled state', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = SettingsController();

    await Future<void>.delayed(Duration.zero);
    controller.setTankMixingEnabled(true);

    expect(controller.state.tankMixingEnabled, isTrue);
  });

  test('settings defaults persist four tank mixing ratios', () async {
    final settings = AppSettingsState.defaults();

    expect(settings.tankForwardPercent, 100);
    expect(settings.tankReversePercent, 100);
    expect(settings.tankLeftTurnPercent, 100);
    expect(settings.tankRightTurnPercent, 100);

    final restored = AppSettingsState.fromStorageString(
      settings.toStorageString(),
    );
    expect(restored.tankForwardPercent, 100);
    expect(restored.tankReversePercent, 100);
    expect(restored.tankLeftTurnPercent, 100);
    expect(restored.tankRightTurnPercent, 100);
  });

  test('settings persists gear ratios with current App defaults', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = SettingsController();

    await Future<void>.delayed(Duration.zero);
    expect(controller.state.gearSettings.lowReversePercent, 100);
    expect(controller.state.gearSettings.lowForwardPercent, 50);
    expect(controller.state.gearSettings.highReversePercent, 100);
    expect(controller.state.gearSettings.highForwardPercent, 100);

    controller.updateGearRatios(lowReverse: 30, highReverse: 60);
    final restored = AppSettingsState.fromStorageString(
      controller.state.toStorageString(),
    );
    expect(restored.gearSettings.lowReversePercent, 30);
    expect(restored.gearSettings.highReversePercent, 60);
  });

  test(
    'settings persists multi-state labels and restores old defaults',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final controller = SettingsController();

      await Future<void>.delayed(Duration.zero);
      final channel = controller.state.channels[2];
      controller.updateChannel(
        2,
        channel.copyWith(
          controlType: AuxControlType.multiState,
          multiStateLabels: const <String>['低速', '中速', '高速'],
        ),
      );

      final restored = AppSettingsState.fromStorageString(
        controller.state.toStorageString(),
      );
      expect(restored.channels[2].multiStateLabels, const <String>[
        '低速',
        '中速',
        '高速',
      ]);

      final legacy = channel.copyWith(multiStateLabels: const <String>[]);
      expect(
        ChannelSetting.fromJson(legacy.toJson()).multiStateLabels,
        const <String>['状态 1', '状态 2', '状态 3'],
      );
    },
  );

  test(
    'settings controller clamps tank mixing ratios to signed range',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final controller = SettingsController();

      await Future<void>.delayed(Duration.zero);
      controller.updateTankMixRatios(
        forward: -120,
        reverse: 120,
        leftTurn: -100,
        rightTurn: 100,
      );

      expect(controller.state.tankForwardPercent, -100);
      expect(controller.state.tankReversePercent, 100);
      expect(controller.state.tankLeftTurnPercent, -100);
      expect(controller.state.tankRightTurnPercent, 100);
    },
  );

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

    expect(state.channels[0].title, '油门');
    expect(state.channels[1].title, '方向');

    expect(state.channels[2].controlType, AuxControlType.multiState);
    expect(state.channels[2].displayName, '辅助1');
    expect(state.channels[3].controlType, AuxControlType.value);
    expect(state.channels[3].singleValue, 25);
  });
}

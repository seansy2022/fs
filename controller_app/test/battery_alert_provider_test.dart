import 'dart:async';

import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/provider/alert_audio_player.dart';
import 'package:controller_app/src/provider/app_provider.dart';
import 'package:controller_app/src/provider/app_settings_provider.dart';
import 'package:controller_app/src/provider/battery_alert_provider.dart';
import 'package:controller_app/src/provider/effective_bluetooth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('disabled battery feature does not start alert outputs', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final infoController = StreamController<ReceiverInfo?>.broadcast();
    final player = _FakeAlertAudioPlayer();
    var vibrationCount = 0;
    final container = ProviderContainer(
      overrides: [
        _testReceiverInfoProvider.overrideWith((ref) => infoController.stream),
        effectiveReceiverInfoProvider.overrideWith((ref) {
          return ref.watch(_testReceiverInfoProvider).valueOrNull;
        }),
        batteryAlertAudioPlayerProvider.overrideWithValue(player),
        batteryAlertVibrationProvider.overrideWith((ref) {
          return () async => vibrationCount++;
        }),
      ],
    );
    addTearDown(() async {
      await infoController.close();
      container.dispose();
    });

    container.read(batteryAlertMonitorProvider);
    infoController.add(testReceiverInfo(0));
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(player.loopedAssets, isEmpty);
    expect(vibrationCount, 0);
  });

  test('background suppresses battery voice but keeps vibration', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final infoController = StreamController<ReceiverInfo?>.broadcast();
    final player = _FakeAlertAudioPlayer();
    var vibrationCount = 0;
    final settings = SettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        lowVoltageEnabled: true,
        batteryAlertPercent: 15,
        batteryVoice: true,
        batteryVibration: true,
      );
    final container = ProviderContainer(
      overrides: [
        appFeatureFlagsProvider.overrideWithValue(
          const AppFeatureFlags(receiverBatteryEnabled: true),
        ),
        appForegroundProvider.overrideWith((ref) => false),
        appSettingsProvider.overrideWith((ref) => settings),
        appSettingsLoadedProvider.overrideWith((ref) => true),
        _testReceiverInfoProvider.overrideWith((ref) => infoController.stream),
        effectiveReceiverInfoProvider.overrideWith((ref) {
          return ref.watch(_testReceiverInfoProvider).valueOrNull;
        }),
        batteryAlertAudioPlayerProvider.overrideWithValue(player),
        batteryAlertVibrationProvider.overrideWith((ref) {
          return () async => vibrationCount++;
        }),
      ],
    );
    addTearDown(() async {
      await infoController.close();
      container.dispose();
    });

    container.read(batteryAlertMonitorProvider);
    infoController.add(testReceiverInfo(0));
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(player.loopedAssets, isEmpty);
    expect(vibrationCount, 1);
  });

  test(
    'battery alert starts immediately and repeats while battery stays low',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final infoController = StreamController<ReceiverInfo?>.broadcast();
      final player = _FakeAlertAudioPlayer();
      var vibrationCount = 0;
      var stopVibrationCount = 0;
      final settings = SettingsController()
        ..state = AppSettingsState.defaults().copyWith(
          lowVoltageEnabled: true,
          batteryAlertPercent: 15,
          batteryVoice: true,
          batteryVibration: true,
        );
      final container = ProviderContainer(
        overrides: [
          appFeatureFlagsProvider.overrideWithValue(
            const AppFeatureFlags(receiverBatteryEnabled: true),
          ),
          appSettingsProvider.overrideWith((ref) => settings),
          appSettingsLoadedProvider.overrideWith((ref) => true),
          _testReceiverInfoProvider.overrideWith(
            (ref) => infoController.stream,
          ),
          effectiveReceiverInfoProvider.overrideWith((ref) {
            return ref.watch(_testReceiverInfoProvider).valueOrNull;
          }),
          batteryAlertAudioPlayerProvider.overrideWithValue(player),
          batteryAlertLanguageCodeProvider.overrideWith((ref) => 'en'),
          batteryAlertDurationProvider.overrideWith((ref) {
            return const Duration(milliseconds: 60);
          }),
          batteryAlertVibrationProvider.overrideWith((ref) {
            return () async => vibrationCount++;
          }),
          batteryAlertStopVibrationProvider.overrideWith((ref) {
            return () async => stopVibrationCount++;
          }),
        ],
      );
      addTearDown(() async {
        await infoController.close();
        container.dispose();
      });

      container.read(batteryAlertMonitorProvider);
      infoController.add(testReceiverInfo(10));

      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(player.loopedAssets.first, 'voice/模型电压低-英文.mp3');
      expect(vibrationCount, 1);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(player.stopCalls, greaterThanOrEqualTo(1));
      expect(stopVibrationCount, greaterThanOrEqualTo(1));
      expect(player.loopedAssets.length, greaterThanOrEqualTo(2));
      expect(vibrationCount, greaterThanOrEqualTo(2));
    },
  );

  test('battery alert stops after battery recovers', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final infoController = StreamController<ReceiverInfo?>.broadcast();
    final player = _FakeAlertAudioPlayer();
    final settings = SettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        lowVoltageEnabled: true,
        batteryAlertPercent: 15,
        batteryVoice: true,
        batteryVibration: false,
      );
    final container = ProviderContainer(
      overrides: [
        appFeatureFlagsProvider.overrideWithValue(
          const AppFeatureFlags(receiverBatteryEnabled: true),
        ),
        appSettingsProvider.overrideWith((ref) => settings),
        appSettingsLoadedProvider.overrideWith((ref) => true),
        _testReceiverInfoProvider.overrideWith((ref) => infoController.stream),
        effectiveReceiverInfoProvider.overrideWith((ref) {
          return ref.watch(_testReceiverInfoProvider).valueOrNull;
        }),
        batteryAlertAudioPlayerProvider.overrideWithValue(player),
        batteryAlertLanguageCodeProvider.overrideWith((ref) => 'zh'),
        batteryAlertDurationProvider.overrideWith((ref) {
          return const Duration(milliseconds: 40);
        }),
      ],
    );
    addTearDown(() async {
      await infoController.close();
      container.dispose();
    });

    container.read(batteryAlertMonitorProvider);
    infoController.add(testReceiverInfo(10));
    await Future<void>.delayed(const Duration(milliseconds: 25));
    infoController.add(testReceiverInfo(100));
    final before = player.loopedAssets.length;
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(player.loopedAssets.first, 'voice/模型电压低-中文.mp3');
    expect(player.loopedAssets.length, before);
    expect(player.stopCalls, greaterThanOrEqualTo(1));
  });
}

final _testReceiverInfoProvider = StreamProvider<ReceiverInfo?>((ref) {
  throw UnimplementedError();
});

class _FakeAlertAudioPlayer implements AlertAudioPlayer {
  final List<String> assets = <String>[];
  final List<String> loopedAssets = <String>[];
  int stopCalls = 0;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> play(String assetPath) async {
    assets.add(assetPath);
  }

  @override
  Future<void> playLoop(String assetPath) async {
    loopedAssets.add(assetPath);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

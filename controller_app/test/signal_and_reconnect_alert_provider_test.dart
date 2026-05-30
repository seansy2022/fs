import 'dart:async';

import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/provider/alert_audio_player.dart';
import 'package:controller_app/src/provider/reconnect_alert_provider.dart';
import 'package:controller_app/src/provider/signal_alert_provider.dart';
import 'package:controller_app/src/provider/simulated_bluetooth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signal alert repeats while connected low signal', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final connection = StreamController<ReceiverConnectionState>.broadcast();
    final rssi = StreamController<int?>.broadcast();
    final player = _FakeAlertAudioPlayer();
    var vibrateCount = 0;
    final settings = SettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        lowSignalEnabled: true,
        signalThreshold: 80,
        signalVoice: true,
        signalVibration: true,
      );
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith((ref) => settings),
        appSettingsLoadedProvider.overrideWith((ref) => true),
        simulatedBluetoothEnabledProvider.overrideWith((ref) => false),
        receiverConnectionProvider.overrideWith((ref) => connection.stream),
        connectedRssiProvider.overrideWith((ref) => rssi.stream),
        alertAudioPlayerProvider.overrideWithValue(player),
        signalAlertLanguageCodeProvider.overrideWith((ref) => 'en'),
        signalAlertIntervalProvider.overrideWith((ref) {
          return const Duration(milliseconds: 20);
        }),
        signalAlertVibrationProvider.overrideWith((ref) {
          return () async => vibrateCount++;
        }),
      ],
    );
    addTearDown(() async {
      await connection.close();
      await rssi.close();
      container.dispose();
    });

    container.read(signalAlertMonitorProvider);
    connection.add(ReceiverConnectionState.connected);
    rssi.add(-80);
    await Future<void>.delayed(const Duration(milliseconds: 55));

    expect(player.assets.first, 'voice/signal_alert_en.mp3');
    expect(player.assets.length, greaterThanOrEqualTo(2));
    expect(vibrateCount, greaterThanOrEqualTo(2));
  });

  test('reconnect alert triggers once per state edge', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final connection = StreamController<ReceiverConnectionState>.broadcast();
    final player = _FakeAlertAudioPlayer();
    var vibrateCount = 0;
    final settings = SettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        reconnectVoice: true,
        reconnectVibration: true,
      );
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith((ref) => settings),
        appSettingsLoadedProvider.overrideWith((ref) => true),
        simulatedBluetoothEnabledProvider.overrideWith((ref) => false),
        receiverConnectionProvider.overrideWith((ref) => connection.stream),
        alertAudioPlayerProvider.overrideWithValue(player),
        reconnectAlertLanguageCodeProvider.overrideWith((ref) => 'zh'),
        reconnectAlertVibrationProvider.overrideWith((ref) {
          return () async => vibrateCount++;
        }),
      ],
    );
    addTearDown(() async {
      await connection.close();
      container.dispose();
    });

    container.read(reconnectAlertMonitorProvider);
    connection.add(ReceiverConnectionState.connected);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    connection.add(ReceiverConnectionState.disconnected);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    connection.add(ReceiverConnectionState.connected);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(player.assets, <String>[
      'voice/reconnect_on_zh.mp3',
      'voice/reconnect_off_zh.mp3',
      'voice/reconnect_on_zh.mp3',
    ]);
    expect(vibrateCount, 3);
  });
}

class _FakeAlertAudioPlayer implements AlertAudioPlayer {
  final List<String> assets = <String>[];
  final List<String> loopedAssets = <String>[];

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
  Future<void> stop() async {}
}

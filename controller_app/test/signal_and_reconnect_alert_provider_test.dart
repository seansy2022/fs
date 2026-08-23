import 'dart:async';

import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/provider/alert_audio_player.dart';
import 'package:controller_app/src/provider/reconnect_alert_provider.dart';
import 'package:controller_app/src/provider/signal_alert_provider.dart';
import 'package:controller_app/src/provider/signal_strength_utils.dart';
import 'package:controller_app/src/provider/simulated_bluetooth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'control signal display linearly maps -100dBm to 0% and -65dBm to 100%',
    () {
      expect(rssiToControlSignalPercent(-65), 100);
      expect(rssiToControlSignalPercent(-80), 57);
      expect(rssiToControlSignalPercent(-90), 29);
      expect(rssiToControlSignalPercent(-100), 0);
      expect(rssiToControlSignalPercent(-101), 0);
      expect(rssiToControlSignalPercent(null), 0);
    },
  );

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
        signalAlertAudioPlayerProvider.overrideWithValue(player),
        signalAlertLanguageCodeProvider.overrideWith((ref) => 'en'),
        signalAlertIntervalProvider.overrideWith((ref) {
          return const Duration(milliseconds: 20);
        }),
        signalAlertConnectionGraceProvider.overrideWith((ref) {
          return Duration.zero;
        }),
        signalAlertRequiredConsecutiveLowReadingsProvider.overrideWith((ref) {
          return 1;
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
    await Future<void>.delayed(const Duration(milliseconds: 20));
    rssi.add(-80);
    await Future<void>.delayed(const Duration(milliseconds: 55));

    expect(player.assets.first, 'voice/signal_alert_en.m4a');
    expect(player.assets.length, greaterThanOrEqualTo(2));
    expect(vibrateCount, greaterThanOrEqualTo(2));
  });

  test('signal alert waits for rssi after connection changes', () async {
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
        signalAlertAudioPlayerProvider.overrideWithValue(player),
        signalAlertLanguageCodeProvider.overrideWith((ref) => 'en'),
        signalAlertIntervalProvider.overrideWith((ref) {
          return const Duration(seconds: 1);
        }),
        signalAlertConnectionGraceProvider.overrideWith((ref) {
          return const Duration(milliseconds: 30);
        }),
        signalAlertRequiredConsecutiveLowReadingsProvider.overrideWith((ref) {
          return 1;
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
    rssi.add(-91);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    connection.add(ReceiverConnectionState.connected);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    connection.add(ReceiverConnectionState.disconnected);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    connection.add(ReceiverConnectionState.connected);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(player.assets, isEmpty);
    expect(vibrateCount, 0);

    rssi.add(-90);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(player.assets, isEmpty);
    expect(vibrateCount, 0);

    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(player.assets, isEmpty);
    expect(vibrateCount, 0);

    rssi.add(-91);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(player.assets, <String>['voice/signal_alert_en.m4a']);
    expect(vibrateCount, 1);
  });

  test('signal alert requires consecutive low RSSI readings', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final connection = StreamController<ReceiverConnectionState>.broadcast();
    final rssi = StreamController<int?>.broadcast();
    final player = _FakeAlertAudioPlayer();
    final settings = SettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        lowSignalEnabled: true,
        signalThreshold: 80,
        signalVoice: true,
      );
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith((ref) => settings),
        appSettingsLoadedProvider.overrideWith((ref) => true),
        simulatedBluetoothEnabledProvider.overrideWith((ref) => false),
        receiverConnectionProvider.overrideWith((ref) => connection.stream),
        connectedRssiProvider.overrideWith((ref) => rssi.stream),
        signalAlertAudioPlayerProvider.overrideWithValue(player),
        signalAlertLanguageCodeProvider.overrideWith((ref) => 'en'),
        signalAlertIntervalProvider.overrideWith((ref) {
          return const Duration(seconds: 1);
        }),
        signalAlertConnectionGraceProvider.overrideWith((ref) {
          return Duration.zero;
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
    await Future<void>.delayed(const Duration(milliseconds: 5));

    rssi.add(-80);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    rssi.add(-85);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    rssi.add(-90);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    rssi.add(-85);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(player.assets, isEmpty);

    rssi.add(-90);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(player.assets, <String>['voice/signal_alert_en.m4a']);
  });

  test(
    'invalid RSSI stops low signal alerts instead of treating it as zero',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final connection = StreamController<ReceiverConnectionState>.broadcast();
      final rssi = StreamController<int?>.broadcast();
      final player = _FakeAlertAudioPlayer();
      final settings = SettingsController()
        ..state = AppSettingsState.defaults().copyWith(
          lowSignalEnabled: true,
          signalThreshold: 80,
          signalVoice: true,
        );
      final container = ProviderContainer(
        overrides: [
          appSettingsProvider.overrideWith((ref) => settings),
          appSettingsLoadedProvider.overrideWith((ref) => true),
          simulatedBluetoothEnabledProvider.overrideWith((ref) => false),
          receiverConnectionProvider.overrideWith((ref) => connection.stream),
          connectedRssiProvider.overrideWith((ref) => rssi.stream),
          signalAlertAudioPlayerProvider.overrideWithValue(player),
          signalAlertLanguageCodeProvider.overrideWith((ref) => 'en'),
          signalAlertConnectionGraceProvider.overrideWith(
            (ref) => Duration.zero,
          ),
          signalAlertRequiredConsecutiveLowReadingsProvider.overrideWith((ref) {
            return 1;
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
      await Future<void>.delayed(const Duration(milliseconds: 5));
      rssi.add(-90);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      rssi.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(player.assets, <String>['voice/signal_alert_en.m4a']);
      expect(player.stopCount, greaterThan(0));
    },
  );

  test('link transition discards queued low signal playback', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final connection = StreamController<ReceiverConnectionState>.broadcast();
    final rssi = StreamController<int?>.broadcast();
    final player = _FakeAlertAudioPlayer();
    final settings = SettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        lowSignalEnabled: true,
        signalThreshold: 80,
        signalVoice: true,
      );
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith((ref) => settings),
        appSettingsLoadedProvider.overrideWith((ref) => true),
        simulatedBluetoothEnabledProvider.overrideWith((ref) => false),
        receiverConnectionProvider.overrideWith((ref) => connection.stream),
        connectedRssiProvider.overrideWith((ref) => rssi.stream),
        signalAlertAudioPlayerProvider.overrideWithValue(player),
        signalAlertLanguageCodeProvider.overrideWith((ref) => 'en'),
        signalAlertConnectionGraceProvider.overrideWith((ref) => Duration.zero),
        signalAlertRequiredConsecutiveLowReadingsProvider.overrideWith((ref) {
          return 1;
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
    await Future<void>.delayed(const Duration(milliseconds: 5));
    rssi.add(-90);
    connection.add(ReceiverConnectionState.disconnected);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(player.assets, isEmpty);
    expect(player.stopCount, greaterThan(0));
  });

  test('out of range RSSI cannot trigger low signal alert', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final connection = StreamController<ReceiverConnectionState>.broadcast();
    final rssi = StreamController<int?>.broadcast();
    final player = _FakeAlertAudioPlayer();
    final settings = SettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        lowSignalEnabled: true,
        signalThreshold: 80,
        signalVoice: true,
      );
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith((ref) => settings),
        appSettingsLoadedProvider.overrideWith((ref) => true),
        simulatedBluetoothEnabledProvider.overrideWith((ref) => false),
        receiverConnectionProvider.overrideWith((ref) => connection.stream),
        connectedRssiProvider.overrideWith((ref) => rssi.stream),
        signalAlertAudioPlayerProvider.overrideWithValue(player),
        signalAlertLanguageCodeProvider.overrideWith((ref) => 'en'),
        signalAlertConnectionGraceProvider.overrideWith((ref) => Duration.zero),
        signalAlertRequiredConsecutiveLowReadingsProvider.overrideWith((ref) {
          return 1;
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
    await Future<void>.delayed(const Duration(milliseconds: 5));
    rssi.add(-127);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(player.assets, isEmpty);
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
      'voice/reconnect_on_zh.m4a',
      'voice/reconnect_off_zh.m4a',
      'voice/reconnect_on_zh.m4a',
    ]);
    expect(vibrateCount, 3);
  });

  test('signal alert cannot replace disconnect voice', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final connection = StreamController<ReceiverConnectionState>.broadcast();
    final rssi = StreamController<int?>.broadcast();
    final reconnectPlayer = _FakeAlertAudioPlayer();
    final signalPlayer = _FakeAlertAudioPlayer();
    final settings = SettingsController()
      ..state = AppSettingsState.defaults().copyWith(
        lowSignalEnabled: true,
        signalThreshold: 80,
        signalVoice: true,
        reconnectVoice: true,
      );
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith((ref) => settings),
        appSettingsLoadedProvider.overrideWith((ref) => true),
        simulatedBluetoothEnabledProvider.overrideWith((ref) => false),
        receiverConnectionProvider.overrideWith((ref) => connection.stream),
        connectedRssiProvider.overrideWith((ref) => rssi.stream),
        alertAudioPlayerProvider.overrideWithValue(reconnectPlayer),
        signalAlertAudioPlayerProvider.overrideWithValue(signalPlayer),
        reconnectAlertLanguageCodeProvider.overrideWith((ref) => 'en'),
        signalAlertLanguageCodeProvider.overrideWith((ref) => 'en'),
        signalAlertConnectionGraceProvider.overrideWith((ref) => Duration.zero),
        signalAlertRequiredConsecutiveLowReadingsProvider.overrideWith((ref) {
          return 1;
        }),
      ],
    );
    addTearDown(() async {
      await connection.close();
      await rssi.close();
      container.dispose();
    });

    container.read(signalAlertMonitorProvider);
    container.read(reconnectAlertMonitorProvider);
    connection.add(ReceiverConnectionState.connected);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    rssi.add(-90);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    connection.add(ReceiverConnectionState.disconnected);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(signalPlayer.assets, <String>['voice/signal_alert_en.m4a']);
    expect(reconnectPlayer.assets.last, 'voice/reconnect_off_en.m4a');
  });
}

class _FakeAlertAudioPlayer implements AlertAudioPlayer {
  final List<String> assets = <String>[];
  final List<String> loopedAssets = <String>[];
  int stopCount = 0;

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
    stopCount++;
  }
}

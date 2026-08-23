import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../core/app_vibration.dart';
import '../core/receiver_battery_status.dart';
import '../features/settings/models/app_settings_state.dart';
import 'alert_audio_player.dart';
import 'app_settings_provider.dart';
import 'device_status_provider.dart';

typedef AlertVibration = Future<void> Function(Duration duration);
typedef StopAlertVibration = Future<void> Function();

final batteryAlertDurationProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 5);
});

final batteryAlertLanguageCodeProvider = Provider<String>((ref) {
  return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
});

final batteryAlertVibrationProvider = Provider<AlertVibration>((ref) {
  return (duration) => AppVibration.alert(duration: duration);
});

final batteryAlertStopVibrationProvider = Provider<StopAlertVibration>((ref) {
  return AppVibration.stop;
});

final batteryAlertMonitorProvider = Provider<BatteryAlertMonitor>((ref) {
  final monitor = BatteryAlertMonitor(ref);
  ref.listen(receiverBatteryStatusProvider, (_, next) {
    monitor.updateBatteryStatus(next);
  });
  ref.listen<AppSettingsState>(appSettingsProvider, (_, __) => monitor.sync());
  ref.onDispose(monitor.dispose);
  return monitor;
});

class BatteryAlertMonitor {
  BatteryAlertMonitor(this._ref)
    : _player = _ref.read(batteryAlertAudioPlayerProvider),
      _vibrate = _ref.read(batteryAlertVibrationProvider),
      _stopVibration = _ref.read(batteryAlertStopVibrationProvider);

  final Ref _ref;
  final AlertAudioPlayer _player;
  final AlertVibration _vibrate;
  final StopAlertVibration _stopVibration;
  Timer? _sessionTimer;
  ReceiverBatteryStatus? _batteryStatus;
  bool _isBelowThreshold = false;
  bool _sessionActive = false;

  /// 同步最新换算后的电池状态，避免直接使用协议原始百分比。
  void updateBatteryStatus(ReceiverBatteryStatus? batteryStatus) {
    _batteryStatus = batteryStatus;
    sync();
  }

  void sync() {
    if (!_ref.read(appSettingsLoadedProvider)) {
      _isBelowThreshold = false;
      _stop();
      return;
    }
    final settings = _ref.read(appSettingsProvider);
    final batteryStatus = _batteryStatus;
    final shouldAlert =
        settings.lowVoltageEnabled &&
        (settings.batteryVoice || settings.batteryVibration) &&
        batteryStatus != null &&
        batteryStatus.isAtOrBelow(settings.batteryAlertPercent);
    if (!shouldAlert) {
      _isBelowThreshold = false;
      _stop();
      return;
    }
    _isBelowThreshold = true;
    if (_sessionActive) {
      return;
    }
    unawaited(_startSession());
  }

  Future<void> _startSession() async {
    _sessionActive = true;
    final settings = _ref.read(appSettingsProvider);
    if (settings.batteryVoice) {
      try {
        await _player.playLoop(
          _batteryAlertAsset(_ref.read(batteryAlertLanguageCodeProvider)),
        );
      } catch (_) {}
    }
    if (settings.batteryVibration) {
      try {
        await _vibrate(_ref.read(batteryAlertDurationProvider));
      } catch (_) {}
    }
    _sessionTimer = Timer(_ref.read(batteryAlertDurationProvider), () {
      _sessionActive = false;
      _safeStopOutputs();
      if (_isBelowThreshold) {
        unawaited(_startSession());
      }
    });
  }

  void _stop() {
    _sessionActive = false;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _safeStopOutputs();
  }

  void dispose() {
    _stop();
  }

  void _safeStopOutputs() {
    try {
      unawaited(_stopVibration());
    } catch (_) {}
    try {
      unawaited(_player.stop());
    } catch (_) {}
  }
}

String _batteryAlertAsset(String languageCode) {
  if (languageCode.toLowerCase().startsWith('zh')) {
    return 'voice/battery_alert_zh.m4a';
  }
  return 'voice/battery_alert_en.m4a';
}

ReceiverInfo testReceiverInfo(int batteryLevel) {
  return ReceiverInfo(
    rfmId: Uint8List(4),
    productModelCode: 1,
    batteryLevel: batteryLevel,
  );
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../core/app_vibration.dart';
import '../features/settings/models/app_settings_state.dart';
import 'alert_audio_player.dart';
import 'app_settings_provider.dart';
import 'effective_bluetooth_provider.dart';
import 'signal_strength_utils.dart';

typedef SignalAlertVibration = Future<void> Function();

final signalAlertIntervalProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 5);
});

final signalAlertConnectionGraceProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 1);
});

final signalAlertRequiredConsecutiveLowReadingsProvider = Provider<int>((ref) {
  return 3;
});

final signalAlertLanguageCodeProvider = Provider<String>((ref) {
  return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
});

final signalAlertVibrationProvider = Provider<SignalAlertVibration>((ref) {
  return () => AppVibration.alert();
});

final signalAlertMonitorProvider = Provider<SignalAlertMonitor>((ref) {
  final monitor = SignalAlertMonitor(ref);
  ref.listen(effectiveReceiverConnectionProvider, (_, next) {
    monitor.updateConnection(next);
  });
  ref.listen(
    effectiveConnectedRssiProvider,
    (_, next) => monitor.updateRssi(next),
  );
  ref.listen<AppSettingsState>(appSettingsProvider, (_, __) => monitor.sync());
  ref.onDispose(monitor.dispose);
  return monitor;
});

class SignalAlertMonitor {
  SignalAlertMonitor(this._ref) : _player = _ref.read(alertAudioPlayerProvider);

  final Ref _ref;
  final AlertAudioPlayer _player;
  Timer? _repeatTimer;
  Timer? _graceTimer;
  ReceiverConnectionState _connection = ReceiverConnectionState.disconnected;
  int? _rssi;
  int _consecutiveLowRssiCount = 0;
  bool _running = false;
  bool _connectionGraceActive = false;

  void updateConnection(ReceiverConnectionState connection) {
    _connection = connection;
    if (connection != ReceiverConnectionState.connected) {
      _rssi = null;
      _consecutiveLowRssiCount = 0;
      _connectionGraceActive = false;
      _graceTimer?.cancel();
      _graceTimer = null;
    } else {
      _startConnectionGrace();
    }
    sync();
  }

  void updateRssi(int? rssi) {
    if (_connection != ReceiverConnectionState.connected) {
      _rssi = null;
      _consecutiveLowRssiCount = 0;
      sync();
      return;
    }
    _rssi = rssi;
    if (!_isLowRssi(rssi)) {
      _consecutiveLowRssiCount = 0;
    } else {
      _consecutiveLowRssiCount++;
    }
    sync();
  }

  void sync() {
    if (!_ref.read(appSettingsLoadedProvider)) {
      _stop();
      return;
    }
    final settings = _ref.read(appSettingsProvider);
    final shouldAlert =
        _connection == ReceiverConnectionState.connected &&
        !_connectionGraceActive &&
        _rssi != null &&
        _consecutiveLowRssiCount >=
            _ref.read(signalAlertRequiredConsecutiveLowReadingsProvider) &&
        settings.lowSignalEnabled &&
        (settings.signalVoice || settings.signalVibration) &&
        rssiToPercent(_rssi) < settings.signalThreshold;
    if (!shouldAlert) {
      _stop();
      return;
    }
    if (_running) {
      return;
    }
    _running = true;
    unawaited(_notify());
    _repeatTimer = Timer.periodic(_ref.read(signalAlertIntervalProvider), (_) {
      unawaited(_notify());
    });
  }

  void _startConnectionGrace() {
    _connectionGraceActive = true;
    _consecutiveLowRssiCount = 0;
    _graceTimer?.cancel();
    _graceTimer = Timer(_ref.read(signalAlertConnectionGraceProvider), () {
      _connectionGraceActive = false;
      sync();
    });
  }

  /// 判断当前 RSSI 是否已低于用户配置的信号阈值。
  bool _isLowRssi(int? rssi) {
    return rssiToPercent(rssi) < _ref.read(appSettingsProvider).signalThreshold;
  }

  Future<void> _notify() async {
    if (!_running) {
      return;
    }
    final settings = _ref.read(appSettingsProvider);
    if (settings.signalVoice) {
      await _player.play(
        _signalAlertAsset(_ref.read(signalAlertLanguageCodeProvider)),
      );
    }
    if (settings.signalVibration) {
      await _ref.read(signalAlertVibrationProvider)();
    }
  }

  void _stop() {
    _running = false;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    unawaited(_player.stop());
  }

  void dispose() {
    _stop();
    _graceTimer?.cancel();
  }
}

String _signalAlertAsset(String languageCode) {
  if (languageCode.toLowerCase().startsWith('zh')) {
    return 'voice/signal_alert_zh.mp3';
  }
  return 'voice/signal_alert_en.mp3';
}

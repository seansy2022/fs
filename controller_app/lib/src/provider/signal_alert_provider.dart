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
  return const Duration(seconds: 5);
});

final signalAlertRequiredConsecutiveLowReadingsProvider = Provider<int>((ref) {
  return 5;
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
  SignalAlertMonitor(this._ref)
    : _player = _ref.read(signalAlertAudioPlayerProvider);

  final Ref _ref;
  final AlertAudioPlayer _player;
  Timer? _repeatTimer;
  Timer? _graceTimer;
  ReceiverConnectionState _connection = ReceiverConnectionState.disconnected;
  int? _rssi;
  int _consecutiveLowRssiCount = 0;
  bool _running = false;
  bool _connectionGraceActive = false;
  bool _awaitingFreshRssi = true;
  int _connectionSession = 0;
  int _notificationVersion = 0;

  void updateConnection(ReceiverConnectionState connection) {
    // 连接状态与 RSSI 分属两个异步流；每次状态变化都必须废弃上一连接的 RSSI。
    _connectionSession++;
    _connection = connection;
    _awaitingFreshRssi = true;
    _log('connection=$connection session=$_connectionSession');
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
    _log(
      'rssi=$rssi state=$_connection session=$_connectionSession '
      'awaitingFresh=$_awaitingFreshRssi valid=${_isValidRssi(rssi)}',
    );
    if (_connection != ReceiverConnectionState.connected ||
        !_isValidRssi(rssi)) {
      // 无效 RSSI（如断链时的 -127）不能按低信号处理。
      _rssi = null;
      _consecutiveLowRssiCount = 0;
      sync();
      return;
    }
    // 只接受本次连接状态之后抵达的 RSSI，避免重连时复用上一会话的缓存值。
    _awaitingFreshRssi = false;
    _rssi = rssi;
    // 连接稳定期内的 RSSI 仅用于页面显示，不能计入低信号连续次数。
    if (_connectionGraceActive) {
      _consecutiveLowRssiCount = 0;
      sync();
      return;
    }
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
    final connectionSession = _connectionSession;
    final shouldAlert = _canAlertInSession(connectionSession, settings);
    _log(
      'sync session=$connectionSession state=$_connection rssi=$_rssi '
      'count=$_consecutiveLowRssiCount grace=$_connectionGraceActive '
      'awaitingFresh=$_awaitingFreshRssi shouldAlert=$shouldAlert '
      'running=$_running',
    );
    if (!shouldAlert) {
      _stop();
      return;
    }
    if (_running) {
      return;
    }
    _running = true;
    final notificationVersion = ++_notificationVersion;
    unawaited(_notify(connectionSession, notificationVersion));
    _repeatTimer = Timer.periodic(_ref.read(signalAlertIntervalProvider), (_) {
      unawaited(_notify(connectionSession, notificationVersion));
    });
  }

  void _startConnectionGrace() {
    _connectionGraceActive = true;
    _consecutiveLowRssiCount = 0;
    _graceTimer?.cancel();
    _graceTimer = Timer(_ref.read(signalAlertConnectionGraceProvider), () {
      _connectionGraceActive = false;
      // 稳定期结束后重新开始计数，不能沿用连接初期的低 RSSI。
      _consecutiveLowRssiCount = 0;
      sync();
    });
  }

  /// 判断当前 RSSI 是否已低于用户配置的信号阈值。
  bool _isLowRssi(int? rssi) {
    return rssiToPercent(rssi) < _ref.read(appSettingsProvider).signalThreshold;
  }

  /// 在播放前让出一个事件循环，确保同批次的断开事件能先取消旧报警。
  Future<void> _notify(int connectionSession, int notificationVersion) async {
    await Future<void>.delayed(Duration.zero);
    if (!_isNotificationActive(connectionSession, notificationVersion)) {
      _log(
        'notify blocked before play session=$connectionSession '
        'notification=$notificationVersion',
      );
      return;
    }
    final settings = _ref.read(appSettingsProvider);
    if (settings.signalVoice) {
      _log(
        'notify play session=$connectionSession notification=$notificationVersion '
        'asset=${_signalAlertAsset(_ref.read(signalAlertLanguageCodeProvider))}',
      );
      await _player.play(
        _signalAlertAsset(_ref.read(signalAlertLanguageCodeProvider)),
      );
    }
    if (!_isNotificationActive(connectionSession, notificationVersion)) {
      _log(
        'notify blocked after play session=$connectionSession '
        'notification=$notificationVersion',
      );
      return;
    }
    if (settings.signalVibration) {
      await _ref.read(signalAlertVibrationProvider)();
    }
  }

  void _stop() {
    _log('stop session=$_connectionSession notification=$_notificationVersion');
    _notificationVersion++;
    _running = false;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    unawaited(_player.stop());
  }

  /// RSSI 低于 -100dBm 已超出页面定义的有效信号区间，通常代表断链占位值。
  bool _isValidRssi(int? rssi) => rssi != null && rssi >= -100 && rssi < 0;

  /// 低信号报警只能使用当前连接会话的新 RSSI，不能依赖缓存状态。
  bool _canAlertInSession(int connectionSession, AppSettingsState settings) {
    return connectionSession == _connectionSession &&
        _connection == ReceiverConnectionState.connected &&
        _ref.read(effectiveReceiverConnectionProvider) ==
            ReceiverConnectionState.connected &&
        !_connectionGraceActive &&
        !_awaitingFreshRssi &&
        _rssi != null &&
        _consecutiveLowRssiCount >=
            _ref.read(signalAlertRequiredConsecutiveLowReadingsProvider) &&
        settings.lowSignalEnabled &&
        (settings.signalVoice || settings.signalVibration) &&
        rssiToPercent(_rssi) < settings.signalThreshold;
  }

  /// 同时校验会话与实时连接状态，阻止异步乱序任务在切换时播放。
  bool _isNotificationActive(int connectionSession, int notificationVersion) {
    if (!_running || notificationVersion != _notificationVersion) {
      return false;
    }
    return _canAlertInSession(
      connectionSession,
      _ref.read(appSettingsProvider),
    );
  }

  /// 统一输出低信号诊断日志，便于和蓝牙、音频日志按时间排序排查。
  void _log(String message) {
    debugPrint('[SignalAlert] $message');
  }

  void dispose() {
    _stop();
    _graceTimer?.cancel();
  }
}

String _signalAlertAsset(String languageCode) {
  if (languageCode.toLowerCase().startsWith('zh')) {
    return 'voice/接收信号低-中文.mp3';
  }
  return 'voice/接收信号低-英文.mp3';
}

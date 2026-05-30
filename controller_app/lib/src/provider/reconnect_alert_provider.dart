import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../core/app_vibration.dart';
import '../features/settings/models/app_settings_state.dart';
import 'alert_audio_player.dart';
import 'app_settings_provider.dart';
import 'effective_bluetooth_provider.dart';

typedef ReconnectAlertVibration = Future<void> Function();

final reconnectAlertLanguageCodeProvider = Provider<String>((ref) {
  return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
});

final reconnectAlertVibrationProvider = Provider<ReconnectAlertVibration>((
  ref,
) {
  return () => AppVibration.alert();
});

final reconnectAlertMonitorProvider = Provider<ReconnectAlertMonitor>((ref) {
  final monitor = ReconnectAlertMonitor(ref);
  ref.listen(effectiveReceiverConnectionProvider, (previous, next) {
    unawaited(monitor.handleTransition(previous, next));
  });
  ref.onDispose(monitor.dispose);
  return monitor;
});

class ReconnectAlertMonitor {
  ReconnectAlertMonitor(this._ref);

  final Ref _ref;

  Future<void> handleTransition(
    ReceiverConnectionState? previous,
    ReceiverConnectionState next,
  ) async {
    if (!_ref.read(appSettingsLoadedProvider)) {
      return;
    }
    if (previous == null || previous == next) {
      return;
    }
    final settings = _ref.read(appSettingsProvider);
    if (!settings.reconnectVoice && !settings.reconnectVibration) {
      return;
    }
    if (previous == ReceiverConnectionState.connected &&
        next == ReceiverConnectionState.disconnected) {
      await _notify(settings, connected: false);
      return;
    }
    final wasDisconnected =
        previous == ReceiverConnectionState.disconnected ||
        previous == ReceiverConnectionState.connecting;
    if (wasDisconnected && next == ReceiverConnectionState.connected) {
      await _notify(settings, connected: true);
    }
  }

  Future<void> _notify(
    AppSettingsState settings, {
    required bool connected,
  }) async {
    if (settings.reconnectVoice) {
      await _ref
          .read(alertAudioPlayerProvider)
          .play(
            _reconnectAsset(
              _ref.read(reconnectAlertLanguageCodeProvider),
              connected,
            ),
          );
    }
    if (settings.reconnectVibration) {
      await _ref.read(reconnectAlertVibrationProvider)();
    }
  }

  void dispose() {}
}

String _reconnectAsset(String languageCode, bool connected) {
  final chinese = languageCode.toLowerCase().startsWith('zh');
  if (connected) {
    return chinese ? 'voice/reconnect_on_zh.mp3' : 'voice/reconnect_on_en.mp3';
  }
  return chinese ? 'voice/reconnect_off_zh.mp3' : 'voice/reconnect_off_en.mp3';
}

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AlertAudioPlayer {
  Future<void> play(String assetPath);

  Future<void> playLoop(String assetPath);

  Future<void> stop();

  Future<void> dispose();
}

class AssetAlertAudioPlayer implements AlertAudioPlayer {
  static final _mixAudioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  AssetAlertAudioPlayer(String playerId)
    : _playerId = playerId,
      _player = AudioPlayer(playerId: playerId);

  final String _playerId;
  final AudioPlayer _player;
  int _requestVersion = 0;

  @override
  Future<void> play(String assetPath) => _play(assetPath, loop: false);

  @override
  Future<void> playLoop(String assetPath) => _play(assetPath, loop: true);

  /// 每次播放使用独立版本，stop 后旧的异步播放请求不能重新启动声音。
  Future<void> _play(String assetPath, {required bool loop}) async {
    final requestVersion = ++_requestVersion;
    debugPrint(
      '[AlertAudio] player=$_playerId request=$requestVersion '
      'play asset=$assetPath loop=$loop',
    );
    await _player.stop();
    if (!_isCurrentRequest(requestVersion)) {
      return;
    }
    await _player.setAudioContext(_mixAudioContext);
    if (!_isCurrentRequest(requestVersion)) {
      return;
    }
    await _player.setVolume(1.0);
    if (!_isCurrentRequest(requestVersion)) {
      return;
    }
    await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    if (!_isCurrentRequest(requestVersion)) {
      return;
    }
    await _playAsset(assetPath, requestVersion);
  }

  @override
  Future<void> stop() async {
    _requestVersion++;
    debugPrint('[AlertAudio] player=$_playerId stop request=$_requestVersion');
    await _player.stop();
  }

  @override
  Future<void> dispose() => _player.dispose();

  Future<void> _playAsset(String assetPath, int requestVersion) async {
    try {
      if (!_isCurrentRequest(requestVersion)) {
        return;
      }
      debugPrint(
        '[AlertAudio] player=$_playerId request=$requestVersion '
        'native play asset=$assetPath',
      );
      await _player.play(AssetSource(assetPath));
      return;
    } catch (_) {
      try {
        if (!_isCurrentRequest(requestVersion)) {
          return;
        }
        await _player.play(AssetSource('assets/$assetPath'));
        return;
      } catch (_) {}
    }
    final alias = _assetAlias(assetPath);
    if (alias != null) {
      try {
        if (!_isCurrentRequest(requestVersion)) {
          return;
        }
        await _player.play(AssetSource(alias));
        return;
      } catch (_) {
        try {
          if (!_isCurrentRequest(requestVersion)) {
            return;
          }
          await _player.play(AssetSource('assets/$alias'));
          return;
        } catch (_) {}
      }
    }
    debugPrint('Alert audio failed for $assetPath');
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: FlutterError('Unable to load alert asset: $assetPath'),
        library: 'alert_audio_player',
        context: ErrorDescription('while playing alert asset $assetPath'),
      ),
    );
  }

  bool _isCurrentRequest(int requestVersion) =>
      requestVersion == _requestVersion;
}

String? _assetAlias(String assetPath) {
  switch (assetPath) {
    case 'voice/模型断开-中文.mp3':
      return 'voice/reconnect_off_zh.m4a';
    case 'voice/模型断开-英文.mp3':
      return 'voice/reconnect_off_en.m4a';
    case 'voice/模型连上-中文.mp3':
      return 'voice/reconnect_on_zh.m4a';
    case 'voice/模型连上-英文.mp3':
      return 'voice/reconnect_on_en.m4a';
  }
  return null;
}

final alertAudioPlayerProvider = Provider<AlertAudioPlayer>((ref) {
  final player = AssetAlertAudioPlayer('alert_audio');
  ref.onDispose(() {
    unawaited(player.dispose());
  });
  return player;
});

/// 低信号报警独立播放，避免抢占接收机连接、断开提示音。
final signalAlertAudioPlayerProvider = Provider<AlertAudioPlayer>((ref) {
  final player = AssetAlertAudioPlayer('signal_alert_audio');
  ref.onDispose(() {
    unawaited(player.dispose());
  });
  return player;
});

final batteryAlertAudioPlayerProvider = Provider<AlertAudioPlayer>((ref) {
  final player = AssetAlertAudioPlayer('battery_alert_audio');
  ref.onDispose(() {
    unawaited(player.dispose());
  });
  return player;
});

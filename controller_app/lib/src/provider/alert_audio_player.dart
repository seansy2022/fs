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
    : _player = AudioPlayer(playerId: playerId);

  final AudioPlayer _player;

  @override
  Future<void> play(String assetPath) async {
    await _player.stop();
    await _player.setAudioContext(_mixAudioContext);
    await _player.setVolume(1.0);
    await _player.setReleaseMode(ReleaseMode.stop);
    await _playAsset(assetPath);
  }

  @override
  Future<void> playLoop(String assetPath) async {
    await _player.stop();
    await _player.setAudioContext(_mixAudioContext);
    await _player.setVolume(1.0);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _playAsset(assetPath);
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();

  Future<void> _playAsset(String assetPath) async {
    try {
      await _player.play(AssetSource(assetPath));
      return;
    } catch (_) {
      try {
        await _player.play(AssetSource('assets/$assetPath'));
        return;
      } catch (_) {}
    }
    final alias = _assetAlias(assetPath);
    if (alias != null) {
      try {
        await _player.play(AssetSource(alias));
        return;
      } catch (_) {
        try {
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
}

String? _assetAlias(String assetPath) {
  switch (assetPath) {
    case 'voice/模型断开-中文.mp3':
      return 'voice/reconnect_off_zh.mp3';
    case 'voice/模型断开-英文.mp3':
      return 'voice/reconnect_off_en.mp3';
    case 'voice/模型连上-中文.mp3':
      return 'voice/reconnect_on_zh.mp3';
    case 'voice/模型连上-英文.mp3':
      return 'voice/reconnect_on_en.mp3';
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

final batteryAlertAudioPlayerProvider = Provider<AlertAudioPlayer>((ref) {
  final player = AssetAlertAudioPlayer('battery_alert_audio');
  ref.onDispose(() {
    unawaited(player.dispose());
  });
  return player;
});

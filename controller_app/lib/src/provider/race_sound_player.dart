import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SoundCue {
  none,
  backgroundMusic,
  launchLow,
  launchHigh,
  drivingLoop,
  reverseLoop,
  brake,
  leftTurnSignal,
  rightTurnSignal,
  gearUp,
  gearDown,
}

class RaceSoundAssetMap {
  const RaceSoundAssetMap({
    required this.backgroundMusic,
    required this.launchLow,
    required this.launchHigh,
    required this.drivingLoop,
    required this.reverseLoop,
    required this.brake,
    required this.turnSignal,
    this.gearUp,
    this.gearDown,
  });

  static const defaults = RaceSoundAssetMap(
    backgroundMusic: 'voice/background_music.mp3',
    launchLow: 'voice/launch_low.mp3',
    launchHigh: 'voice/launch_high.mp3',
    drivingLoop: 'voice/driving_loop.mp3',
    reverseLoop: 'voice/reverse_loop.mp3',
    brake: 'voice/brake.mp3',
    turnSignal: 'voice/turn_signal.mp3',
  );

  final String backgroundMusic;
  final String launchLow;
  final String launchHigh;
  final String drivingLoop;
  final String reverseLoop;
  final String brake;
  final String turnSignal;
  final String? gearUp;
  final String? gearDown;

  String? assetForCue(SoundCue cue) {
    switch (cue) {
      case SoundCue.none:
        return null;
      case SoundCue.backgroundMusic:
        return backgroundMusic;
      case SoundCue.launchLow:
        return launchLow;
      case SoundCue.launchHigh:
        return launchHigh;
      case SoundCue.drivingLoop:
        return drivingLoop;
      case SoundCue.reverseLoop:
        return reverseLoop;
      case SoundCue.brake:
        return brake;
      case SoundCue.leftTurnSignal:
      case SoundCue.rightTurnSignal:
        return turnSignal;
      case SoundCue.gearUp:
        return gearUp;
      case SoundCue.gearDown:
        return gearDown;
    }
  }
}

abstract class RaceSoundPlayer {
  Stream<void> get onEffectComplete;

  Future<bool> playBackground();

  Future<void> stopBackground();

  Future<bool> playEffect(SoundCue cue, {required bool loop});

  Future<void> stopEffect();

  Future<void> dispose();
}

class AudioplayersRaceSoundPlayer implements RaceSoundPlayer {
  static const _logPrefix = '[race-sound]';
  static const _backgroundVolume = 0.22;
  static const _effectVolume = 1.0;
  static final _mixAudioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  AudioplayersRaceSoundPlayer({
    required RaceSoundAssetMap assets,
    String backgroundPlayerId = 'race_background',
    String effectPlayerId = 'race_effects',
  }) : _assets = assets,
       _backgroundPlayer = AudioPlayer(playerId: backgroundPlayerId),
       _effectPlayer = AudioPlayer(playerId: effectPlayerId);

  final RaceSoundAssetMap _assets;
  final AudioPlayer _backgroundPlayer;
  final AudioPlayer _effectPlayer;

  @override
  Stream<void> get onEffectComplete =>
      _effectPlayer.onPlayerComplete.map((_) {});

  @override
  Future<bool> playBackground() async {
    final assetPath = _assets.assetForCue(SoundCue.backgroundMusic);
    if (assetPath == null) {
      await _backgroundPlayer.stop();
      return false;
    }
    try {
      await _backgroundPlayer.stop();
      await _backgroundPlayer.setAudioContext(_mixAudioContext);
      await _backgroundPlayer.setVolume(_backgroundVolume);
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.play(AssetSource(assetPath));
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '$_logPrefix background failed asset=$assetPath error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      await _backgroundPlayer.stop();
      return false;
    }
  }

  @override
  Future<void> stopBackground() => _backgroundPlayer.stop();

  @override
  Future<bool> playEffect(SoundCue cue, {required bool loop}) async {
    final assetPath = _assets.assetForCue(cue);
    if (assetPath == null) {
      await _effectPlayer.stop();
      return false;
    }
    try {
      await _effectPlayer.stop();
      await _effectPlayer.setAudioContext(_mixAudioContext);
      await _effectPlayer.setVolume(_effectVolume);
      await _effectPlayer.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.stop,
      );
      await _effectPlayer.play(AssetSource(assetPath));
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '$_logPrefix effect failed cue=${cue.name} asset=$assetPath '
        'loop=$loop error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      await _effectPlayer.stop();
      return false;
    }
  }

  @override
  Future<void> stopEffect() => _effectPlayer.stop();

  @override
  Future<void> dispose() async {
    await _backgroundPlayer.dispose();
    await _effectPlayer.dispose();
  }
}

typedef RaceSoundPlayerFactory = RaceSoundPlayer Function();

final raceSoundAssetMapProvider = Provider<RaceSoundAssetMap>((ref) {
  return RaceSoundAssetMap.defaults;
});

final raceSoundPlayerFactoryProvider = Provider<RaceSoundPlayerFactory>((ref) {
  return () =>
      AudioplayersRaceSoundPlayer(assets: ref.watch(raceSoundAssetMapProvider));
});

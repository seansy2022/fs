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
    // 新行驶音时长与交叉淡入淡出周期一致，避免循环时出现停顿。
    drivingLoop: 'voice/汽车行驶中.mp3',
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
  static const _drivingLoopDuration = Duration(milliseconds: 2670);
  static const _drivingLoopOverlap = Duration(milliseconds: 120);
  static const _drivingLoopFadeSteps = 4;
  static final _mixAudioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  AudioplayersRaceSoundPlayer({
    required RaceSoundAssetMap assets,
    String backgroundPlayerId = 'race_background',
    String effectPlayerId = 'race_effects',
    String loopEffectPlayerId = 'race_effects_loop',
  }) : _assets = assets,
       _backgroundPlayer = AudioPlayer(playerId: backgroundPlayerId),
       _effectPlayer = AudioPlayer(playerId: effectPlayerId),
       _loopEffectPlayer = AudioPlayer(playerId: loopEffectPlayerId);

  final RaceSoundAssetMap _assets;
  final AudioPlayer _backgroundPlayer;
  final AudioPlayer _effectPlayer;
  final AudioPlayer _loopEffectPlayer;

  Timer? _drivingLoopTimer;
  AudioPlayer? _activeDrivingLoopPlayer;
  AudioPlayer? _standbyDrivingLoopPlayer;
  int _drivingLoopSession = 0;

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
      debugPrint('$_logPrefix background failed asset=$assetPath error=$error');
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
      await stopEffect();
      return false;
    }
    if (cue == SoundCue.drivingLoop && loop) {
      return _playDrivingLoopGaplessly(assetPath);
    }
    try {
      await _stopDrivingLoop();
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
  Future<void> stopEffect() async {
    await _stopDrivingLoop();
    await _effectPlayer.stop();
  }

  @override
  Future<void> dispose() async {
    await _stopDrivingLoop();
    await Future.wait<void>([
      _backgroundPlayer.dispose(),
      _effectPlayer.dispose(),
      _loopEffectPlayer.dispose(),
    ]);
  }

  /// 使用两个播放器交替播放行驶音，避开 Android 原生循环的间隔。
  Future<bool> _playDrivingLoopGaplessly(String assetPath) async {
    await _stopDrivingLoop();
    await _effectPlayer.stop();
    final session = ++_drivingLoopSession;
    try {
      await Future.wait<void>([
        _prepareDrivingLoopPlayer(_effectPlayer, assetPath, _effectVolume),
        _prepareDrivingLoopPlayer(_loopEffectPlayer, assetPath, 0),
      ]);
      if (session != _drivingLoopSession) {
        return false;
      }
      // 先建立循环会话，再调用播放；否则激活校验会使首次播放提前返回。
      _activeDrivingLoopPlayer = _effectPlayer;
      _standbyDrivingLoopPlayer = _loopEffectPlayer;
      await _effectPlayer.resume();
      if (!_isDrivingLoopActive(session)) {
        return false;
      }
      _scheduleDrivingLoopTransition(session);
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '$_logPrefix gapless driving loop failed asset=$assetPath '
        'error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      await _stopDrivingLoop();
      return false;
    }
  }

  /// 预加载备用播放器，切换时只需要快速恢复播放。
  Future<void> _prepareDrivingLoopPlayer(
    AudioPlayer player,
    String assetPath,
    double volume,
  ) async {
    await player.stop();
    await player.setAudioContext(_mixAudioContext);
    await player.setVolume(volume);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(assetPath));
  }

  /// 在结束前启动备用播放器，通过短暂交叉淡入淡出覆盖播放器切换耗时。
  void _scheduleDrivingLoopTransition(int session) {
    _drivingLoopTimer?.cancel();
    _drivingLoopTimer = Timer(
      _drivingLoopDuration - _drivingLoopOverlap,
      () => unawaited(_crossFadeDrivingLoop(session)),
    );
  }

  /// 交替当前与备用播放器；会话变更后立即放弃旧的异步操作。
  Future<void> _crossFadeDrivingLoop(int session) async {
    final outgoing = _activeDrivingLoopPlayer;
    final incoming = _standbyDrivingLoopPlayer;
    if (outgoing == null ||
        incoming == null ||
        !_isDrivingLoopActive(session)) {
      return;
    }
    try {
      await incoming.setVolume(0);
      if (!_isDrivingLoopActive(session)) {
        return;
      }
      await incoming.resume();
      for (var step = 1; step <= _drivingLoopFadeSteps; step++) {
        if (!_isDrivingLoopActive(session)) {
          return;
        }
        final progress = step / _drivingLoopFadeSteps;
        await Future.wait<void>([
          outgoing.setVolume(_effectVolume * (1 - progress)),
          incoming.setVolume(_effectVolume * progress),
        ]);
        if (step < _drivingLoopFadeSteps) {
          await Future<void>.delayed(
            Duration(
              microseconds:
                  _drivingLoopOverlap.inMicroseconds ~/
                  (_drivingLoopFadeSteps - 1),
            ),
          );
        }
      }
      if (!_isDrivingLoopActive(session)) {
        return;
      }
      await outgoing.stop();
      if (!_isDrivingLoopActive(session)) {
        return;
      }
      _activeDrivingLoopPlayer = incoming;
      _standbyDrivingLoopPlayer = outgoing;
      _scheduleDrivingLoopTransition(session);
    } catch (error, stackTrace) {
      debugPrint('$_logPrefix driving loop transition failed error=$error');
      debugPrintStack(stackTrace: stackTrace);
      if (_isDrivingLoopActive(session)) {
        await _stopDrivingLoop();
      }
    }
  }

  /// 终止当前循环并使已经排队的定时器、异步淡入淡出立即失效。
  Future<void> _stopDrivingLoop() async {
    _drivingLoopSession++;
    _drivingLoopTimer?.cancel();
    _drivingLoopTimer = null;
    _activeDrivingLoopPlayer = null;
    _standbyDrivingLoopPlayer = null;
    await Future.wait<void>([_effectPlayer.stop(), _loopEffectPlayer.stop()]);
  }

  bool _isDrivingLoopActive(int session) =>
      session == _drivingLoopSession && _activeDrivingLoopPlayer != null;
}

typedef RaceSoundPlayerFactory = RaceSoundPlayer Function();

final raceSoundAssetMapProvider = Provider<RaceSoundAssetMap>((ref) {
  return RaceSoundAssetMap.defaults;
});

final raceSoundPlayerFactoryProvider = Provider<RaceSoundPlayerFactory>((ref) {
  return () =>
      AudioplayersRaceSoundPlayer(assets: ref.watch(raceSoundAssetMapProvider));
});

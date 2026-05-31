import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'race_sound_player.dart';
import '../features/control/controllers/control_controller.dart';

enum ControlDriveState {
  idle,
  launchLow,
  launchHigh,
  forward,
  reverse,
  braking,
  forwardLeft,
  forwardRight,
  reverseLeft,
  reverseRight,
  leftTurnSignal,
  rightTurnSignal,
  gearUp,
  gearDown,
}

enum ControlAnimationState {
  idle,
  forward,
  forwardLeft,
  forwardRight,
  reverse,
  reverseLeft,
  reverseRight,
}

class ControlPresentationState {
  const ControlPresentationState({
    required this.backgroundSoundEnabled,
    required this.effectSoundEnabled,
    required this.driveState,
    required this.animationState,
    required this.musicCue,
    required this.effectCue,
    required this.isPageActive,
  });

  const ControlPresentationState.initial()
    : backgroundSoundEnabled = true,
      effectSoundEnabled = true,
      driveState = ControlDriveState.idle,
      animationState = ControlAnimationState.idle,
      musicCue = SoundCue.none,
      effectCue = SoundCue.none,
      isPageActive = false;

  final bool backgroundSoundEnabled;
  final bool effectSoundEnabled;
  final ControlDriveState driveState;
  final ControlAnimationState animationState;
  final SoundCue musicCue;
  final SoundCue effectCue;
  final bool isPageActive;

  ControlPresentationState copyWith({
    bool? backgroundSoundEnabled,
    bool? effectSoundEnabled,
    ControlDriveState? driveState,
    ControlAnimationState? animationState,
    SoundCue? musicCue,
    SoundCue? effectCue,
    bool? isPageActive,
  }) {
    return ControlPresentationState(
      backgroundSoundEnabled:
          backgroundSoundEnabled ?? this.backgroundSoundEnabled,
      effectSoundEnabled: effectSoundEnabled ?? this.effectSoundEnabled,
      driveState: driveState ?? this.driveState,
      animationState: animationState ?? this.animationState,
      musicCue: musicCue ?? this.musicCue,
      effectCue: effectCue ?? this.effectCue,
      isPageActive: isPageActive ?? this.isPageActive,
    );
  }
}

class ControlPresentationDecision {
  const ControlPresentationDecision({
    required this.driveState,
    required this.animationState,
    required this.effectCue,
    required this.effectLoop,
  });

  final ControlDriveState driveState;
  final ControlAnimationState animationState;
  final SoundCue effectCue;
  final bool effectLoop;
}

final controlPresentationProvider =
    StateNotifierProvider.autoDispose<
      ControlPresentationController,
      ControlPresentationState
    >((ref) {
      return ControlPresentationController(
        soundPlayer: ref.watch(raceSoundPlayerFactoryProvider)(),
      );
    });

class ControlPresentationController
    extends StateNotifier<ControlPresentationState> {
  ControlPresentationController({required RaceSoundPlayer soundPlayer})
    : _soundPlayer = soundPlayer,
      super(const ControlPresentationState.initial()) {
    _effectCompleteSubscription = _soundPlayer.onEffectComplete.listen((_) {
      unawaited(_handleEffectComplete());
    });
  }

  static const movementThreshold = 0.15;
  static const launchHighThreshold = 0.5;
  static const brakePreviousThreshold = 0.55;
  static const minimumTriggerGap = Duration(milliseconds: 350);

  final RaceSoundPlayer _soundPlayer;

  StreamSubscription<void>? _effectCompleteSubscription;
  ControlScreenState? _latestControlState;
  SoundCue _activeEffectCue = SoundCue.none;
  bool _activeEffectLoop = false;
  DateTime? _lastOneShotAt;
  Future<void> _decisionQueue = Future<void>.value();
  int _decisionVersion = 0;

  Future<void> enterPage() async {
    if (state.isPageActive) {
      return;
    }
    state = state.copyWith(
      isPageActive: true,
      musicCue: _desiredMusicCue(true),
    );
    await _syncBackgroundSound();
    await _reconcileWithControlState(force: true);
  }

  Future<void> leavePage() async {
    if (!state.isPageActive) {
      return;
    }
    _latestControlState = null;
    _activeEffectCue = SoundCue.none;
    _activeEffectLoop = false;
    state = state.copyWith(
      isPageActive: false,
      driveState: ControlDriveState.idle,
      animationState: ControlAnimationState.idle,
      musicCue: SoundCue.none,
      effectCue: SoundCue.none,
    );
    await Future.wait<void>([
      _soundPlayer.stopBackground(),
      _soundPlayer.stopEffect(),
    ]);
  }

  Future<void> toggleBackgroundSound() async {
    final enabled = !state.backgroundSoundEnabled;
    state = state.copyWith(
      backgroundSoundEnabled: enabled,
      musicCue: _desiredMusicCue(enabled),
    );
    await _syncBackgroundSound();
  }

  Future<void> toggleEffectSound() async {
    final enabled = !state.effectSoundEnabled;
    state = state.copyWith(effectSoundEnabled: enabled);
    if (!enabled) {
      _activeEffectCue = SoundCue.none;
      _activeEffectLoop = false;
      await _soundPlayer.stopEffect();
      return;
    }
    await _reconcileWithControlState(force: true);
  }

  Future<void> bindControlState(ControlScreenState controlState) async {
    final previousState = _latestControlState ?? controlState;
    _latestControlState = controlState;
    final decision = deriveControlPresentationDecision(
      previousState: previousState,
      nextState: controlState,
    );
    final version = ++_decisionVersion;
    await _enqueueDecision(decision, force: false, version: version);
  }

  Future<void> _reconcileWithControlState({required bool force}) async {
    final controlState = _latestControlState;
    if (controlState == null) {
      await _applyDecision(
        const ControlPresentationDecision(
          driveState: ControlDriveState.idle,
          animationState: ControlAnimationState.idle,
          effectCue: SoundCue.none,
          effectLoop: false,
        ),
        force: force,
        version: _decisionVersion,
      );
      return;
    }

    final decision = deriveControlPresentationDecision(
      previousState: controlState,
      nextState: controlState,
      forceContinuousState: true,
    );
    await _applyDecision(decision, force: force, version: _decisionVersion);
  }

  Future<void> _enqueueDecision(
    ControlPresentationDecision decision, {
    required bool force,
    required int version,
  }) {
    _decisionQueue = _decisionQueue
        .catchError((_) {})
        .then((_) => _applyDecision(decision, force: force, version: version));
    return _decisionQueue;
  }

  Future<void> _applyDecision(
    ControlPresentationDecision decision, {
    required bool force,
    required int version,
  }) async {
    if (_isStale(version, force: force)) {
      return;
    }
    state = state.copyWith(
      driveState: decision.driveState,
      animationState: decision.animationState,
      musicCue: _desiredMusicCue(state.backgroundSoundEnabled),
      effectCue: decision.effectCue,
    );

    if (!state.isPageActive) {
      return;
    }

    if (!state.effectSoundEnabled) {
      if (_activeEffectCue != SoundCue.none) {
        _activeEffectCue = SoundCue.none;
        _activeEffectLoop = false;
        await _soundPlayer.stopEffect();
      }
      return;
    }

    if (decision.effectCue == SoundCue.none) {
      if (_activeEffectCue != SoundCue.none || force) {
        _activeEffectCue = SoundCue.none;
        _activeEffectLoop = false;
        await _soundPlayer.stopEffect();
      }
      return;
    }

    if (!force &&
        decision.effectLoop &&
        _activeEffectCue == decision.effectCue &&
        _activeEffectLoop == decision.effectLoop) {
      return;
    }

    if (!decision.effectLoop && !_canTriggerOneShot(force: force)) {
      return;
    }

    if (_isStale(version, force: force)) {
      return;
    }

    _activeEffectCue = decision.effectCue;
    _activeEffectLoop = decision.effectLoop;
    if (!decision.effectLoop) {
      _lastOneShotAt = DateTime.now();
    }

    final didStart = await _soundPlayer.playEffect(
      decision.effectCue,
      loop: decision.effectLoop,
    );
    if (!didStart && !decision.effectLoop) {
      _activeEffectCue = SoundCue.none;
      _activeEffectLoop = false;
      await _reconcileWithControlState(force: true);
    }
  }

  Future<void> _syncBackgroundSound() async {
    if (!state.isPageActive || !state.backgroundSoundEnabled) {
      await _soundPlayer.stopBackground();
      return;
    }
    await _soundPlayer.playBackground();
  }

  SoundCue _desiredMusicCue(bool backgroundSoundEnabled) {
    return state.isPageActive && backgroundSoundEnabled
        ? SoundCue.backgroundMusic
        : SoundCue.none;
  }

  bool _canTriggerOneShot({required bool force}) {
    if (force) {
      return true;
    }
    final lastOneShotAt = _lastOneShotAt;
    if (lastOneShotAt == null) {
      return true;
    }
    return DateTime.now().difference(lastOneShotAt) >= minimumTriggerGap;
  }

  Future<void> _handleEffectComplete() async {
    if (_activeEffectLoop || !state.isPageActive || !state.effectSoundEnabled) {
      return;
    }
    _activeEffectCue = SoundCue.none;
    await _reconcileWithControlState(force: true);
  }

  @override
  void dispose() {
    unawaited(_effectCompleteSubscription?.cancel());
    unawaited(_soundPlayer.dispose());
    super.dispose();
  }

  bool _isStale(int version, {required bool force}) {
    return !force && version != _decisionVersion;
  }
}

@visibleForTesting
ControlPresentationDecision deriveControlPresentationDecision({
  required ControlScreenState previousState,
  required ControlScreenState nextState,
  bool forceContinuousState = false,
}) {
  final animationState = deriveAnimationState(nextState);
  final throttle = nextState.throttle;
  final previousThrottle = previousState.throttle;
  final enteredForward =
      previousThrottle <= ControlPresentationController.movementThreshold &&
      throttle > ControlPresentationController.movementThreshold;
  final braking =
      previousThrottle >=
          ControlPresentationController.brakePreviousThreshold &&
      throttle < -ControlPresentationController.movementThreshold;
  final gearChanged = previousState.highGear != nextState.highGear;

  if (gearChanged) {
    return ControlPresentationDecision(
      driveState: nextState.highGear
          ? ControlDriveState.gearUp
          : ControlDriveState.gearDown,
      animationState: animationState,
      effectCue: nextState.highGear ? SoundCue.gearUp : SoundCue.gearDown,
      effectLoop: false,
    );
  }

  if (nextState.leftSignalOn) {
    return ControlPresentationDecision(
      driveState: ControlDriveState.leftTurnSignal,
      animationState: animationState,
      effectCue: SoundCue.leftTurnSignal,
      effectLoop: true,
    );
  }

  if (nextState.rightSignalOn) {
    return ControlPresentationDecision(
      driveState: ControlDriveState.rightTurnSignal,
      animationState: animationState,
      effectCue: SoundCue.rightTurnSignal,
      effectLoop: true,
    );
  }

  if (braking) {
    return ControlPresentationDecision(
      driveState: ControlDriveState.braking,
      animationState: animationState,
      effectCue: SoundCue.brake,
      effectLoop: false,
    );
  }

  if (enteredForward) {
    final highLaunch =
        throttle > ControlPresentationController.launchHighThreshold;
    return ControlPresentationDecision(
      driveState: highLaunch
          ? ControlDriveState.launchHigh
          : ControlDriveState.launchLow,
      animationState: animationState,
      effectCue: highLaunch ? SoundCue.launchHigh : SoundCue.launchLow,
      effectLoop: false,
    );
  }

  if (throttle > ControlPresentationController.movementThreshold) {
    final turnCue = _turnSignalCueFor(animationState);
    return ControlPresentationDecision(
      driveState: _driveStateFromAnimation(animationState),
      animationState: animationState,
      effectCue: turnCue ?? SoundCue.drivingLoop,
      effectLoop: true,
    );
  }

  if (throttle < -ControlPresentationController.movementThreshold) {
    final turnCue = _turnSignalCueFor(animationState);
    return ControlPresentationDecision(
      driveState: _driveStateFromAnimation(animationState),
      animationState: animationState,
      effectCue: turnCue ?? SoundCue.reverseLoop,
      effectLoop: true,
    );
  }

  if (forceContinuousState) {
    return ControlPresentationDecision(
      driveState: _driveStateFromAnimation(animationState),
      animationState: animationState,
      effectCue: SoundCue.none,
      effectLoop: false,
    );
  }

  return const ControlPresentationDecision(
    driveState: ControlDriveState.idle,
    animationState: ControlAnimationState.idle,
    effectCue: SoundCue.none,
    effectLoop: false,
  );
}

@visibleForTesting
ControlAnimationState deriveAnimationState(ControlScreenState state) {
  final throttle = state.throttle;
  final steering = state.steering;

  if (throttle > ControlPresentationController.movementThreshold) {
    if (steering < -ControlPresentationController.movementThreshold) {
      return ControlAnimationState.forwardLeft;
    }
    if (steering > ControlPresentationController.movementThreshold) {
      return ControlAnimationState.forwardRight;
    }
    return ControlAnimationState.forward;
  }

  if (throttle < -ControlPresentationController.movementThreshold) {
    if (steering < -ControlPresentationController.movementThreshold) {
      return ControlAnimationState.reverseLeft;
    }
    if (steering > ControlPresentationController.movementThreshold) {
      return ControlAnimationState.reverseRight;
    }
    return ControlAnimationState.reverse;
  }

  return ControlAnimationState.idle;
}

String? overlayAnimationAssetFor(ControlAnimationState state) {
  switch (state) {
    case ControlAnimationState.idle:
      return null;
    case ControlAnimationState.forward:
      return 'assets/wepb/control_forward.webp';
    case ControlAnimationState.forwardLeft:
      return 'assets/wepb/control_forward_left.webp';
    case ControlAnimationState.forwardRight:
      return 'assets/wepb/control_forward_right.webp';
    case ControlAnimationState.reverse:
      return 'assets/wepb/control_reverse.webp';
    case ControlAnimationState.reverseLeft:
      return 'assets/wepb/control_reverse_left.webp';
    case ControlAnimationState.reverseRight:
      return 'assets/wepb/control_reverse_right.webp';
  }
}

ControlDriveState _driveStateFromAnimation(ControlAnimationState state) {
  switch (state) {
    case ControlAnimationState.idle:
      return ControlDriveState.idle;
    case ControlAnimationState.forward:
      return ControlDriveState.forward;
    case ControlAnimationState.forwardLeft:
      return ControlDriveState.forwardLeft;
    case ControlAnimationState.forwardRight:
      return ControlDriveState.forwardRight;
    case ControlAnimationState.reverse:
      return ControlDriveState.reverse;
    case ControlAnimationState.reverseLeft:
      return ControlDriveState.reverseLeft;
    case ControlAnimationState.reverseRight:
      return ControlDriveState.reverseRight;
  }
}

SoundCue? _turnSignalCueFor(ControlAnimationState state) {
  switch (state) {
    case ControlAnimationState.forwardLeft:
    case ControlAnimationState.reverseLeft:
      return SoundCue.leftTurnSignal;
    case ControlAnimationState.forwardRight:
    case ControlAnimationState.reverseRight:
      return SoundCue.rightTurnSignal;
    case ControlAnimationState.idle:
    case ControlAnimationState.forward:
    case ControlAnimationState.reverse:
      return null;
  }
}

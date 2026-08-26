import 'dart:async';

import 'package:controller_app/src/features/control/controllers/control_controller.dart';
import 'package:controller_app/src/features/control/controllers/control_runtime_store.dart';
import 'package:controller_app/src/provider/control_presentation_provider.dart';
import 'package:controller_app/src/provider/race_sound_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('default driving sound uses the supplied vehicle audio asset', () {
    expect(
      RaceSoundAssetMap.defaults.assetForCue(SoundCue.drivingLoop),
      'voice/汽车行驶中.mp3',
    );
  });

  group('deriveControlPresentationDecision', () {
    test('plays low launch when entering forward below 50%', () {
      final command = deriveControlPresentationDecision(
        previousState: const ControlScreenState(throttle: 0),
        nextState: const ControlScreenState(throttle: 0.3),
      );

      expect(command.driveState, ControlDriveState.launchLow);
      expect(command.animationState, ControlAnimationState.forward);
      expect(command.effectCue, SoundCue.launchLow);
      expect(command.effectLoop, isFalse);
    });

    test('plays animation and launch sound for minimal forward input', () {
      final command = deriveControlPresentationDecision(
        previousState: const ControlScreenState(throttle: 0),
        nextState: const ControlScreenState(throttle: 0.01),
      );

      expect(command.driveState, ControlDriveState.launchLow);
      expect(command.animationState, ControlAnimationState.forward);
      expect(command.effectCue, SoundCue.launchLow);
    });

    test('uses driving loop for sustained minimal forward input', () {
      final command = deriveControlPresentationDecision(
        previousState: const ControlScreenState(throttle: 0.01),
        nextState: const ControlScreenState(throttle: 0.02),
        forceContinuousState: true,
      );

      expect(command.animationState, ControlAnimationState.forward);
      expect(command.effectCue, SoundCue.drivingLoop);
      expect(command.effectLoop, isTrue);
    });

    test('plays high launch when entering forward above 50%', () {
      final command = deriveControlPresentationDecision(
        previousState: const ControlScreenState(throttle: 0),
        nextState: const ControlScreenState(throttle: 0.7),
      );

      expect(command.driveState, ControlDriveState.launchHigh);
      expect(command.effectCue, SoundCue.launchHigh);
    });

    test('switches to driving loop during sustained forward motion', () {
      final command = deriveControlPresentationDecision(
        previousState: const ControlScreenState(throttle: 0.35),
        nextState: const ControlScreenState(throttle: 0.4),
        forceContinuousState: true,
      );

      expect(command.driveState, ControlDriveState.forward);
      expect(command.effectCue, SoundCue.drivingLoop);
      expect(command.effectLoop, isTrue);
    });

    test('does not play braking when throttle returns to neutral', () {
      final command = deriveControlPresentationDecision(
        previousState: const ControlScreenState(throttle: 0.8),
        nextState: const ControlScreenState(throttle: 0),
      );

      expect(command.driveState, ControlDriveState.idle);
      expect(command.effectCue, SoundCue.none);
    });

    test('plays braking when throttle crosses from forward into reverse', () {
      final command = deriveControlPresentationDecision(
        previousState: const ControlScreenState(throttle: 0.8),
        nextState: const ControlScreenState(throttle: -0.4),
      );

      expect(command.driveState, ControlDriveState.braking);
      expect(command.effectCue, SoundCue.brake);
      expect(command.effectLoop, isFalse);
    });

    test('switches to reverse loop during sustained reverse motion', () {
      final command = deriveControlPresentationDecision(
        previousState: const ControlScreenState(throttle: -0.3),
        nextState: const ControlScreenState(throttle: -0.4),
        forceContinuousState: true,
      );

      expect(command.driveState, ControlDriveState.reverse);
      expect(command.effectCue, SoundCue.reverseLoop);
      expect(command.effectLoop, isTrue);
    });

    test('uses left turn signal loop while left signal is enabled', () {
      final command = deriveControlPresentationDecision(
        previousState: const ControlScreenState(throttle: 0.4),
        nextState: const ControlScreenState(throttle: 0.4, leftSignalOn: true),
      );

      expect(command.driveState, ControlDriveState.leftTurnSignal);
      expect(command.effectCue, SoundCue.leftTurnSignal);
      expect(command.effectLoop, isTrue);
    });

    test('switches animation to forward left when steering left', () {
      final command = deriveControlPresentationDecision(
        previousState: const ControlScreenState(throttle: 0.4, steering: 0),
        nextState: const ControlScreenState(throttle: 0.4, steering: -0.4),
        forceContinuousState: true,
      );

      expect(command.driveState, ControlDriveState.forwardLeft);
      expect(command.animationState, ControlAnimationState.forwardLeft);
    });

    test('uses left turn cue while steering left in motion', () {
      final command = deriveControlPresentationDecision(
        previousState: const ControlScreenState(throttle: 0.4, steering: 0),
        nextState: const ControlScreenState(throttle: 0.4, steering: -0.4),
        forceContinuousState: true,
      );

      expect(command.effectCue, SoundCue.leftTurnSignal);
      expect(command.effectLoop, isTrue);
    });

    test('uses gear down cue when shifting from high to low gear', () {
      final command = deriveControlPresentationDecision(
        previousState: const ControlScreenState(highGear: true, throttle: 0.5),
        nextState: const ControlScreenState(highGear: false, throttle: 0.5),
      );

      expect(command.driveState, ControlDriveState.gearDown);
      expect(command.effectCue, SoundCue.gearDown);
    });
  });

  test(
    'saved disabled sound switches stay muted when entering control page',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final runtimeStore = ControlRuntimeStore();
      await runtimeStore.saveSoundState(
        const StoredControlSoundState(
          backgroundSoundEnabled: false,
          effectSoundEnabled: false,
        ),
      );
      final player = _FakeRaceSoundPlayer();
      final controller = ControlPresentationController(
        soundPlayer: player,
        runtimeStore: runtimeStore,
      );
      addTearDown(controller.dispose);

      await controller.enterPage();

      expect(controller.state.backgroundSoundEnabled, isFalse);
      expect(controller.state.effectSoundEnabled, isFalse);
      expect(player.playBackgroundCount, 0);
    },
  );
}

class _FakeRaceSoundPlayer implements RaceSoundPlayer {
  int playBackgroundCount = 0;

  @override
  Stream<void> get onEffectComplete => const Stream<void>.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> playBackground() async {
    playBackgroundCount++;
    return true;
  }

  @override
  Future<bool> playEffect(SoundCue cue, {required bool loop}) async => true;

  @override
  Future<void> stopBackground() async {}

  @override
  Future<void> stopEffect() async {}
}

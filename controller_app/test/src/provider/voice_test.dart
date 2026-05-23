import 'package:controller_app/src/features/control/controllers/control_controller.dart';
import 'package:controller_app/src/provider/control_presentation_provider.dart';
import 'package:controller_app/src/provider/race_sound_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
        nextState: const ControlScreenState(throttle: 0.05),
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
}

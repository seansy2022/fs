import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

class ControlScreenState {
  const ControlScreenState({
    this.steering = 0,
    this.throttle = 0,
    this.trim = 0,
    this.headlightsOn = false,
    this.warningLightsOn = false,
    this.gyroEnabled = false,
    this.backgroundMusicOn = true,
    this.soundEffectsOn = true,
    this.highGear = false,
    this.leftSignalOn = false,
    this.rightSignalOn = false,
    this.sliderButtonsVisible = false,
    this.loopActive = false,
  });

  final double steering;
  final double throttle;
  final int trim;
  final bool headlightsOn;
  final bool warningLightsOn;
  final bool gyroEnabled;
  final bool backgroundMusicOn;
  final bool soundEffectsOn;
  final bool highGear;
  final bool leftSignalOn;
  final bool rightSignalOn;
  final bool sliderButtonsVisible;
  final bool loopActive;

  ControlScreenState copyWith({
    double? steering,
    double? throttle,
    int? trim,
    bool? headlightsOn,
    bool? warningLightsOn,
    bool? gyroEnabled,
    bool? backgroundMusicOn,
    bool? soundEffectsOn,
    bool? highGear,
    bool? leftSignalOn,
    bool? rightSignalOn,
    bool? sliderButtonsVisible,
    bool? loopActive,
  }) {
    return ControlScreenState(
      steering: steering ?? this.steering,
      throttle: throttle ?? this.throttle,
      trim: trim ?? this.trim,
      headlightsOn: headlightsOn ?? this.headlightsOn,
      warningLightsOn: warningLightsOn ?? this.warningLightsOn,
      gyroEnabled: gyroEnabled ?? this.gyroEnabled,
      backgroundMusicOn: backgroundMusicOn ?? this.backgroundMusicOn,
      soundEffectsOn: soundEffectsOn ?? this.soundEffectsOn,
      highGear: highGear ?? this.highGear,
      leftSignalOn: leftSignalOn ?? this.leftSignalOn,
      rightSignalOn: rightSignalOn ?? this.rightSignalOn,
      sliderButtonsVisible: sliderButtonsVisible ?? this.sliderButtonsVisible,
      loopActive: loopActive ?? this.loopActive,
    );
  }
}

class ControlController extends StateNotifier<ControlScreenState> {
  ControlController(this._repository) : super(const ControlScreenState());

  final ReceiverRepository _repository;

  Future<void> activate() async {
    await _repository.startControlLoop();
    state = state.copyWith(loopActive: true);
    await _push();
  }

  Future<void> deactivate() async {
    await _repository.stopControlLoop();
    state = state.copyWith(loopActive: false, throttle: 0, steering: 0);
    await _push();
  }

  Future<void> setSteering(double value) async {
    state = state.copyWith(steering: value.clamp(-1, 1));
    await _push();
  }

  Future<void> setThrottle(double value) async {
    state = state.copyWith(throttle: value.clamp(-1, 1));
    await _push();
  }

  Future<void> adjustTrim(int delta) async {
    state = state.copyWith(trim: (state.trim + delta).clamp(-50, 50));
    await _push();
  }

  Future<void> toggleHeadlights() async {
    state = state.copyWith(headlightsOn: !state.headlightsOn);
    await _push();
  }

  Future<void> toggleWarningLights() async {
    state = state.copyWith(warningLightsOn: !state.warningLightsOn);
    await _push();
  }

  Future<void> toggleGyro() async {
    state = state.copyWith(gyroEnabled: !state.gyroEnabled);
    await _push();
  }

  void toggleBackgroundMusic() {
    state = state.copyWith(backgroundMusicOn: !state.backgroundMusicOn);
  }

  void toggleSoundEffects() {
    state = state.copyWith(soundEffectsOn: !state.soundEffectsOn);
  }

  Future<void> toggleGear(bool highGear) async {
    state = state.copyWith(highGear: highGear);
    await _push();
  }

  Future<void> setTurnSignal({
    required bool leftOn,
    required bool rightOn,
  }) async {
    state = state.copyWith(leftSignalOn: leftOn, rightSignalOn: rightOn);
    await _push();
  }

  void toggleSliderButtons() {
    state = state.copyWith(sliderButtonsVisible: !state.sliderButtonsVisible);
  }

  Future<void> _push() async {
    final steeringUs = (1500 + (state.steering * 500) + (state.trim * 2))
        .round()
        .clamp(1000, 2000);
    final throttleUs = (1500 - (state.throttle * 500)).round().clamp(
      1000,
      2000,
    );
    final auxChannels = <int>[
      state.headlightsOn ? 2000 : 1000,
      state.warningLightsOn ? 2000 : 1000,
      state.highGear ? 2000 : 1000,
      state.gyroEnabled ? 2000 : 1000,
      state.throttle < -0.15 ? 2000 : 1000,
      state.throttle > 0.15 ? 2000 : 1000,
      state.leftSignalOn ? 2000 : 1000,
      state.rightSignalOn ? 2000 : 1000,
    ];
    await _repository.updateControlValues(
      ReceiverControlValues(
        throttle: throttleUs,
        steering: steeringUs,
        auxChannels: auxChannels,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_repository.stopControlLoop());
    super.dispose();
  }
}

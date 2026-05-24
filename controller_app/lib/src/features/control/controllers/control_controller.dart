import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../../../provider/app_settings_provider.dart';
import '../../settings/models/app_settings_state.dart';

class ControlScreenState {
  const ControlScreenState({
    this.steering = 0,
    this.throttle = 0,
    this.trim = 0,
    this.headlightsOn = false,
    this.warningLightsOn = false,
    this.gyroEnabled = false,
    this.highGear = false,
    this.leftSignalOn = false,
    this.rightSignalOn = false,
    this.parkLocked = false,
    this.sliderButtonsVisible = false,
    this.loopActive = false,
  });

  final double steering;
  final double throttle;
  final int trim;
  final bool headlightsOn;
  final bool warningLightsOn;
  final bool gyroEnabled;
  final bool highGear;
  final bool leftSignalOn;
  final bool rightSignalOn;
  final bool parkLocked;
  final bool sliderButtonsVisible;
  final bool loopActive;

  ControlScreenState copyWith({
    double? steering,
    double? throttle,
    int? trim,
    bool? headlightsOn,
    bool? warningLightsOn,
    bool? gyroEnabled,
    bool? highGear,
    bool? leftSignalOn,
    bool? rightSignalOn,
    bool? parkLocked,
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
      highGear: highGear ?? this.highGear,
      leftSignalOn: leftSignalOn ?? this.leftSignalOn,
      rightSignalOn: rightSignalOn ?? this.rightSignalOn,
      parkLocked: parkLocked ?? this.parkLocked,
      sliderButtonsVisible: sliderButtonsVisible ?? this.sliderButtonsVisible,
      loopActive: loopActive ?? this.loopActive,
    );
  }
}

class ControlController extends StateNotifier<ControlScreenState> {
  static const _gyroPromptFrameInterval = Duration(milliseconds: 20);
  static const _controlStateStep = 0.01;

  ControlController(this._ref, this._repository)
    : super(const ControlScreenState());

  final Ref _ref;
  final ReceiverRepository _repository;
  double _touchSteering = 0;
  double _touchThrottle = 0;
  double _gyroSteering = 0;
  double _gyroThrottle = 0;
  Timer? _pendingGyroSyncTimer;
  DateTime? _lastGyroSyncAt;
  bool _gyroSyncInFlight = false;
  bool _gyroSyncPending = false;
  ReceiverControlValues? _lastPushedValues;

  bool get gyroEnabled => state.gyroEnabled;

  Future<void> activate() async {
    await _repository.startControlLoop();
    state = state.copyWith(loopActive: true);
    await _syncPromptAndPush();
  }

  Future<void> deactivate() async {
    await _repository.stopControlLoop();
    _cancelGyroSync();
    _touchSteering = 0;
    _touchThrottle = 0;
    _gyroSteering = 0;
    _gyroThrottle = 0;
    state = state.copyWith(loopActive: false);
    await _syncPromptAndPush();
  }

  Future<void> setGyroPrompt({
    required double steering,
    required double throttle,
  }) async {
    _gyroSteering = steering.clamp(-1, 1);
    _gyroThrottle = throttle.clamp(-1, 1);
    _gyroSyncPending = true;
    await _scheduleGyroPromptSync();
  }

  Future<void> clearGyroPrompt() async {
    _gyroSteering = 0;
    _gyroThrottle = 0;
    await _syncPromptAndPush();
  }

  Future<void> clearTouchPrompt() async {
    _touchSteering = 0;
    _touchThrottle = 0;
    await _syncPromptAndPush();
  }

  Future<void> _syncPromptAndPush() async {
    final mode = _ref.read(appSettingsProvider).gyroMode;
    final gyroActive = state.gyroEnabled;
    final useGyroSteering =
        mode == GyroMode.directionOnly || mode == GyroMode.all;
    final useGyroThrottle =
        mode == GyroMode.throttleOnly || mode == GyroMode.all;
    if (state.parkLocked) {
      if (state.steering != 0 || state.throttle != 0) {
        state = state.copyWith(steering: 0, throttle: 0);
      }
      await _push(steering: 0, throttle: 0);
      return;
    }
    final gyroSteering = gyroActive && useGyroSteering ? _gyroSteering : 0.0;
    final gyroThrottle = gyroActive && useGyroThrottle ? _gyroThrottle : 0.0;
    final steering = _roundControlValue(
      (_touchSteering + gyroSteering).clamp(-1, 1).toDouble(),
    );
    final throttle = _roundControlValue(
      (_touchThrottle + gyroThrottle).clamp(-1, 1).toDouble(),
    );
    if (state.steering != steering || state.throttle != throttle) {
      state = state.copyWith(steering: steering, throttle: throttle);
    }
    await _push(steering: steering, throttle: throttle);
  }

  Future<void> setSteering(double value) async {
    if (state.parkLocked) {
      return;
    }
    _touchSteering = value.clamp(-1, 1);
    await _syncPromptAndPush();
  }

  Future<void> setThrottle(double value) async {
    if (state.parkLocked) {
      return;
    }
    _touchThrottle = value.clamp(-1, 1);
    await _syncPromptAndPush();
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

  Future<void> setGyroEnabled(bool enabled) async {
    if (state.gyroEnabled == enabled) {
      return;
    }
    state = state.copyWith(gyroEnabled: enabled);
    if (!enabled) {
      _cancelGyroSync();
      _gyroSteering = 0;
      _gyroThrottle = 0;
    }
    await _syncPromptAndPush();
  }

  Future<void> toggleGyro() async {
    await setGyroEnabled(!state.gyroEnabled);
  }

  Future<void> toggleGear(bool highGear) async {
    state = state.copyWith(highGear: highGear, parkLocked: false);
    await _push();
  }

  Future<void> setParkLocked(bool locked) async {
    if (state.parkLocked == locked) {
      return;
    }
    _touchSteering = 0;
    _touchThrottle = 0;
    _gyroSteering = 0;
    _gyroThrottle = 0;
    state = state.copyWith(parkLocked: locked);
    await _syncPromptAndPush();
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

  Future<void> _scheduleGyroPromptSync() async {
    if (!state.gyroEnabled) {
      return;
    }
    if (_gyroSyncInFlight) {
      return;
    }
    final now = DateTime.now();
    final lastGyroSyncAt = _lastGyroSyncAt;
    if (lastGyroSyncAt == null ||
        now.difference(lastGyroSyncAt) >= _gyroPromptFrameInterval) {
      await _flushGyroPromptSync();
      return;
    }
    final remaining = _gyroPromptFrameInterval - now.difference(lastGyroSyncAt);
    _pendingGyroSyncTimer ??= Timer(remaining, () {
      _pendingGyroSyncTimer = null;
      unawaited(_flushGyroPromptSync());
    });
  }

  Future<void> _flushGyroPromptSync() async {
    if (!state.gyroEnabled || !_gyroSyncPending || _gyroSyncInFlight) {
      return;
    }
    _pendingGyroSyncTimer?.cancel();
    _pendingGyroSyncTimer = null;
    _gyroSyncInFlight = true;
    _gyroSyncPending = false;
    _lastGyroSyncAt = DateTime.now();
    try {
      await _syncPromptAndPush();
    } finally {
      _gyroSyncInFlight = false;
      if (_gyroSyncPending && state.gyroEnabled) {
        unawaited(_scheduleGyroPromptSync());
      }
    }
  }

  void _cancelGyroSync() {
    _pendingGyroSyncTimer?.cancel();
    _pendingGyroSyncTimer = null;
    _gyroSyncPending = false;
    _gyroSyncInFlight = false;
    _lastGyroSyncAt = null;
  }

  Future<void> _push({double? steering, double? throttle}) async {
    final effectiveSteering = steering ?? state.steering;
    final effectiveThrottle = throttle ?? state.throttle;
    final steeringUs = (1500 + (effectiveSteering * 500) + (state.trim * 2))
        .round()
        .clamp(1000, 2000);
    final throttleUs = (1500 - (effectiveThrottle * 500)).round().clamp(
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
    final values = ReceiverControlValues(
      throttle: throttleUs,
      steering: steeringUs,
      auxChannels: auxChannels,
    );
    final lastPushedValues = _lastPushedValues;
    if (lastPushedValues != null &&
        lastPushedValues.throttle == values.throttle &&
        lastPushedValues.steering == values.steering &&
        listEquals(lastPushedValues.auxChannels, values.auxChannels)) {
      return;
    }
    _lastPushedValues = values;
    await _repository.updateControlValues(values);
  }

  double _roundControlValue(double value) {
    return (value / _controlStateStep).round() * _controlStateStep;
  }

  @override
  void dispose() {
    _cancelGyroSync();
    unawaited(_repository.stopControlLoop());
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../../../provider/app_settings_provider.dart';
import '../../settings/models/app_settings_state.dart';

class AuxChannelRuntimeState {
  const AuxChannelRuntimeState({
    this.controlType = AuxControlType.disabled,
    this.selectedIndex = 0,
    this.switchOn = false,
  });

  final AuxControlType controlType;
  final int selectedIndex;
  final bool switchOn;

  AuxChannelRuntimeState copyWith({
    AuxControlType? controlType,
    int? selectedIndex,
    bool? switchOn,
  }) {
    return AuxChannelRuntimeState(
      controlType: controlType ?? this.controlType,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      switchOn: switchOn ?? this.switchOn,
    );
  }
}

AuxChannelRuntimeState resolveAuxChannelRuntime(
  ChannelSetting setting,
  AuxChannelRuntimeState runtime,
) {
  if (runtime.controlType != setting.controlType) {
    return AuxChannelRuntimeState(controlType: setting.controlType);
  }
  if (setting.controlType != AuxControlType.multiState) {
    return runtime;
  }
  final values = setting.multiStateValues.isEmpty
      ? const <double>[0]
      : setting.multiStateValues;
  final safeIndex = runtime.selectedIndex.clamp(0, values.length - 1);
  return safeIndex == runtime.selectedIndex
      ? runtime
      : runtime.copyWith(selectedIndex: safeIndex);
}

String auxChannelControlLabel(
  ChannelSetting setting,
  AuxChannelRuntimeState runtime,
) {
  final resolved = resolveAuxChannelRuntime(setting, runtime);
  return switch (setting.controlType) {
    AuxControlType.disabled => setting.displayName,
    AuxControlType.switchControl =>
      '${setting.displayName} ${resolved.switchOn ? '开' : '关'}',
    AuxControlType.multiState =>
      '${setting.displayName} 状态${resolved.selectedIndex + 1}',
    AuxControlType.value =>
      '${setting.displayName} ${setting.singleValue.round()}%',
  };
}

List<String> auxChannelControlLabels(
  ChannelSetting setting,
  AuxChannelRuntimeState runtime,
) {
  final resolved = resolveAuxChannelRuntime(setting, runtime);
  return switch (setting.controlType) {
    AuxControlType.disabled => const <String>[],
    AuxControlType.switchControl => <String>[
      '${setting.displayName} ${resolved.switchOn ? '开' : '关'}',
    ],
    AuxControlType.multiState => List<String>.generate(
      setting.multiStateValues.isEmpty ? 1 : setting.multiStateValues.length,
      (index) => '${setting.displayName} 状态${index + 1}',
    ),
    AuxControlType.value => <String>[
      '${setting.displayName} ${setting.singleValue.round()}%',
    ],
  };
}

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
    this.ch3Runtime = const AuxChannelRuntimeState(),
    this.ch4Runtime = const AuxChannelRuntimeState(),
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
  final AuxChannelRuntimeState ch3Runtime;
  final AuxChannelRuntimeState ch4Runtime;
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
    AuxChannelRuntimeState? ch3Runtime,
    AuxChannelRuntimeState? ch4Runtime,
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
      ch3Runtime: ch3Runtime ?? this.ch3Runtime,
      ch4Runtime: ch4Runtime ?? this.ch4Runtime,
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

  Future<void> pressAuxChannel(int channelIndex, {int? selectedIndex}) async {
    final settings = _ref.read(appSettingsProvider);
    final setting = _channelSettingAt(settings.channels, channelIndex);
    if (setting.controlType == AuxControlType.disabled) {
      return;
    }
    final runtime = _alignedRuntime(channelIndex, setting);
    final nextRuntime = switch (setting.controlType) {
      AuxControlType.switchControl => runtime.copyWith(
        switchOn: !runtime.switchOn,
      ),
      AuxControlType.multiState => runtime.copyWith(
        selectedIndex:
            selectedIndex ??
            (runtime.selectedIndex + 1) %
                _normalizedMultiStateValues(setting).length,
      ),
      AuxControlType.value => runtime,
      AuxControlType.disabled => runtime,
    };
    _setRuntime(channelIndex, nextRuntime);
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
    final settings = _ref.read(appSettingsProvider);
    final steeringUs = (1500 + (effectiveSteering * 500) + (state.trim * 2))
        .round()
        .clamp(1000, 2000);
    final throttleUs = (1500 - (effectiveThrottle * 500)).round().clamp(
      1000,
      2000,
    );
    final auxChannels = <int>[
      _auxOutputForChannel(settings, 2),
      _auxOutputForChannel(settings, 3),
      state.highGear ? 2000 : 1000,
      state.gyroEnabled ? 2000 : 1000,
      effectiveThrottle < -0.15 ? 2000 : 1000,
      effectiveThrottle > 0.15 ? 2000 : 1000,
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

  int _auxOutputForChannel(AppSettingsState settings, int channelIndex) {
    final setting = _channelSettingAt(settings.channels, channelIndex);
    final runtime = _alignedRuntime(channelIndex, setting);
    final percent = switch (setting.controlType) {
      AuxControlType.disabled => 0.0,
      AuxControlType.switchControl =>
        runtime.switchOn ? setting.switchValues[0] : setting.switchValues[1],
      AuxControlType.multiState => _normalizedMultiStateValues(
        setting,
      )[runtime.selectedIndex],
      AuxControlType.value => setting.singleValue,
    };
    return (1500 + (percent * 5)).round().clamp(1000, 2000);
  }

  AuxChannelRuntimeState _alignedRuntime(
    int channelIndex,
    ChannelSetting setting,
  ) {
    final runtime = _runtimeFor(channelIndex);
    if (runtime.controlType != setting.controlType) {
      return AuxChannelRuntimeState(controlType: setting.controlType);
    }
    if (setting.controlType == AuxControlType.multiState) {
      final values = _normalizedMultiStateValues(setting);
      final safeIndex = runtime.selectedIndex.clamp(0, values.length - 1);
      if (safeIndex != runtime.selectedIndex) {
        return runtime.copyWith(selectedIndex: safeIndex);
      }
    }
    return runtime;
  }

  AuxChannelRuntimeState _runtimeFor(int channelIndex) {
    return channelIndex == 2 ? state.ch3Runtime : state.ch4Runtime;
  }

  void _setRuntime(int channelIndex, AuxChannelRuntimeState runtime) {
    state = channelIndex == 2
        ? state.copyWith(ch3Runtime: runtime)
        : state.copyWith(ch4Runtime: runtime);
  }

  List<double> _normalizedMultiStateValues(ChannelSetting setting) {
    return setting.multiStateValues.isEmpty
        ? const <double>[0]
        : setting.multiStateValues;
  }

  ChannelSetting _channelSettingAt(List<ChannelSetting> channels, int index) {
    if (index < channels.length) {
      return channels[index];
    }
    return ChannelSetting(
      channelLabel: 'CH${index + 1}',
      title: '辅助通道',
      function: AuxiliaryFunction.none,
      displayName: '辅助${index - 1}',
      controlType: AuxControlType.disabled,
      switchValues: const <double>[100, -100],
      multiStateValues: const <double>[0, 0, 0],
      singleValue: 0,
      lowPercent: -100,
      highPercent: 100,
      trimPercent: 0,
      reversed: false,
    );
  }

  @override
  void dispose() {
    _cancelGyroSync();
    unawaited(_repository.stopControlLoop());
    super.dispose();
  }
}

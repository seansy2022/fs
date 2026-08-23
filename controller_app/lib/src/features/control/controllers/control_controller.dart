import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../provider/app_settings_provider.dart';
import 'channel_output_mapper.dart';
import 'tank_mixer.dart';
import 'control_aux_runtime_store.dart';
import 'control_runtime_store.dart';
import '../../settings/models/app_settings_state.dart';
import '../../settings/models/aux_channel_value_rules.dart';
import '../../settings/models/gear_settings.dart';

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
      '${AppText.tr(setting.displayName)} '
          '${AppText.tr(resolved.switchOn ? '开' : '关')}',
    AuxControlType.multiState =>
      '${AppText.tr(setting.displayName)} '
          '${AppText.tr(_multiStateLabels(setting)[resolved.selectedIndex])}',
    AuxControlType.value =>
      '${AppText.tr(setting.displayName)} ${setting.singleValue.round()}%',
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
      '${AppText.tr(setting.displayName)} '
          '${AppText.tr(resolved.switchOn ? '开' : '关')}',
    ],
    AuxControlType.multiState => _multiStateLabels(
      setting,
    ).map(AppText.tr).toList(growable: false),
    AuxControlType.value => <String>[
      '${AppText.tr(setting.displayName)} ${setting.singleValue.round()}%',
    ],
  };
}

List<String> _multiStateLabels(ChannelSetting setting) {
  final values = normalizeAuxMultiStateValues(setting.multiStateValues);
  return normalizeAuxMultiStateLabels(
    setting.multiStateLabels,
    stateCount: values.length,
  );
}

class ControlScreenState {
  const ControlScreenState({
    this.steering = 0,
    this.throttle = 0,
    this.throttleTrim = 0,
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
  final int throttleTrim;
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
    int? throttleTrim,
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
      throttleTrim: throttleTrim ?? this.throttleTrim,
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
  static const _gyroPromptFrameInterval = Duration(milliseconds: 30);
  static const _controlStateStep = 0.01;

  ControlController(
    this._ref,
    this._repository, {
    ControlAuxRuntimeStore? auxRuntimeStore,
    ControlRuntimeStore? runtimeStore,
  }) : _auxRuntimeStore = auxRuntimeStore ?? ControlAuxRuntimeStore(),
       _runtimeStore = runtimeStore ?? ControlRuntimeStore(),
       super(const ControlScreenState()) {
    unawaited(_loadSavedAuxRuntime(_ref.read(appSettingsProvider)));
    _inputRuntimeRestoreFuture = _loadSavedInputRuntime();
    _ref.listen<AppSettingsState>(appSettingsProvider, (previous, next) {
      if (previous?.gearSettings == next.gearSettings || !state.loopActive) {
        return;
      }
      // 设置页修改挡位比例时，立刻刷新控制缓存供下一帧心跳发送。
      unawaited(_syncPromptAndPush());
    });
  }

  final Ref _ref;
  final ReceiverRepository _repository;
  final ControlAuxRuntimeStore _auxRuntimeStore;
  final ControlRuntimeStore _runtimeStore;
  late final Future<void> _inputRuntimeRestoreFuture;
  double _touchSteering = 0;
  double _touchThrottle = 0;
  double _gyroSteering = 0;
  double _gyroThrottle = 0;
  Timer? _pendingGyroSyncTimer;
  DateTime? _lastGyroSyncAt;
  bool _gyroSyncInFlight = false;
  bool _gyroSyncPending = false;
  bool _controlOutputSuspended = false;
  ReceiverControlValues? _lastPushedValues;

  bool get gyroEnabled => state.gyroEnabled;

  /// 等待控制页输入状态恢复完成，供页面开始倒计时前调用。
  Future<void> restoreInputRuntime() => _inputRuntimeRestoreFuture;

  /// 新进入控制页时允许后续倒计时启动控制循环。
  void prepareControlSession() {
    _controlOutputSuspended = false;
  }

  Future<void> activate() async {
    if (_controlOutputSuspended) {
      return;
    }
    await _syncPromptAndPush();
    if (_controlOutputSuspended) {
      return;
    }
    await _repository.startControlLoop();
    if (_controlOutputSuspended) {
      await _repository.stopControlLoop();
      return;
    }
    state = state.copyWith(loopActive: true);
  }

  /// 停止后台或已退出页面的连续控制帧，不额外补发控制数据。
  Future<void> suspendControlOutput() async {
    _controlOutputSuspended = true;
    _cancelGyroSync();
    _touchSteering = 0;
    _touchThrottle = 0;
    _gyroSteering = 0;
    _gyroThrottle = 0;
    await _repository.stopControlLoop();
    if (!mounted) {
      return;
    }
    state = state.copyWith(loopActive: false);
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
    if (_controlOutputSuspended) {
      return;
    }
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
    final throttle = _applyGearToThrottle(
      _roundControlValue(
        (_touchThrottle + gyroThrottle).clamp(-1, 1).toDouble(),
      ),
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
    await setSteeringTrim(state.trim + delta);
  }

  /// 设置油门微调值，并立刻按当前控制量刷新接收机输出。
  Future<void> setThrottleTrim(int value) async {
    final trim = value.clamp(-50, 50);
    if (state.throttleTrim == trim) {
      return;
    }
    state = state.copyWith(throttleTrim: trim);
    unawaited(_saveInputRuntime());
    await _push();
  }

  /// 设置方向微调值，并立刻按当前控制量刷新接收机输出。
  Future<void> setSteeringTrim(int value) async {
    final trim = value.clamp(-50, 50);
    if (state.trim == trim) {
      return;
    }
    state = state.copyWith(trim: trim);
    unawaited(_saveInputRuntime());
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
    unawaited(_saveInputRuntime());
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
    await _syncPromptAndPush();
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
    try {
      await _saveAuxRuntime(channelIndex, nextRuntime);
    } catch (_) {
      // 本地状态保存失败不应阻断当前蓝牙控制输出。
    }
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
    unawaited(_saveInputRuntime());
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
    // 应用进入后台或控制页退出后，任何异步事件都不能继续写入接收机。
    if (_controlOutputSuspended) {
      return;
    }
    final effectiveSteering = steering ?? state.steering;
    final effectiveThrottle = throttle ?? state.throttle;
    final settings = _ref.read(appSettingsProvider);
    final throttleSetting = _channelSettingAt(settings.channels, 0);
    final steeringSetting = _channelSettingAt(settings.channels, 1);
    final steeringUs = mapSteeringInputToUs(
      steering: effectiveSteering,
      lowPercent: steeringSetting.lowPercent,
      centerPercent: steeringSetting.trimPercent,
      highPercent: steeringSetting.highPercent,
      trimStep: state.trim,
    );
    final throttleUs = mapThrottleInputToUs(
      throttle: effectiveThrottle,
      lowPercent: throttleSetting.lowPercent,
      centerPercent: throttleSetting.trimPercent,
      highPercent: throttleSetting.highPercent,
      trimStep: state.throttleTrim,
    );
    final output = settings.tankMixingEnabled
        ? mixTankOutputs(
            throttleUs: throttleUs,
            steeringUs: steeringUs,
            ch1: calibratePrimaryChannel(
              lowPercent: throttleSetting.lowPercent,
              centerOffsetUs: throttleSetting.trimPercent,
              highPercent: throttleSetting.highPercent,
            ),
            ch2: calibratePrimaryChannel(
              lowPercent: steeringSetting.lowPercent,
              centerOffsetUs: steeringSetting.trimPercent,
              highPercent: steeringSetting.highPercent,
            ),
            ratios: TankMixRatios(
              forward: settings.tankForwardPercent,
              reverse: settings.tankReversePercent,
              leftTurn: settings.tankLeftTurnPercent,
              rightTurn: settings.tankRightTurnPercent,
            ),
          )
        : null;
    final auxChannels = <int>[
      _auxOutputForChannel(settings, 2),
      _auxOutputForChannel(settings, 3),
      0,
      0,
      0,
      0,
      0,
      0,
    ];
    // 反向必须作用在校准、Trim 和履带混控之后的最终硬件输出值。
    final finalThrottleUs = output?.ch1Us ?? throttleUs;
    final finalSteeringUs = output?.ch2Us ?? steeringUs;
    final values = ReceiverControlValues(
      throttle: throttleSetting.reversed
          ? reversePrimaryOutputAroundCenter(finalThrottleUs)
          : finalThrottleUs,
      steering: steeringSetting.reversed
          ? reversePrimaryOutputAroundCenter(finalSteeringUs)
          : finalSteeringUs,
      auxChannels: auxChannels,
    );
    final lastPushedValues = _lastPushedValues;
    if (lastPushedValues != null &&
        lastPushedValues.throttle == values.throttle &&
        lastPushedValues.steering == values.steering &&
        listEquals(lastPushedValues.auxChannels, values.auxChannels)) {
      return;
    }
    if (settings.tankMixingEnabled) {
      // 输出最终发送给接收机的两路履带 PWM，便于核对混控、限幅和反向结果。
      debugPrint('🚀ch1：${values.throttle}  🚀ch2：${values.steering}');
    }
    _lastPushedValues = values;
    await _repository.updateControlValues(values);
  }

  double _roundControlValue(double value) {
    return (value / _controlStateStep).round() * _controlStateStep;
  }

  double _applyGearToThrottle(double throttle) {
    return applyGearThrottleRatio(
      throttle: throttle,
      highGear: state.highGear,
      settings: _ref.read(appSettingsProvider).gearSettings,
    );
  }

  int _auxOutputForChannel(AppSettingsState settings, int channelIndex) {
    final setting = _channelSettingAt(settings.channels, channelIndex);
    final runtime = _alignedRuntime(channelIndex, setting);
    return _pulseOutputForChannel(setting, runtime);
  }

  int _pulseOutputForChannel(
    ChannelSetting setting,
    AuxChannelRuntimeState runtime,
  ) {
    if (setting.controlType == AuxControlType.disabled) {
      return 1000;
    }
    final percent = switch (setting.controlType) {
      AuxControlType.disabled => 0.0,
      AuxControlType.switchControl =>
        runtime.switchOn ? setting.switchValues[0] : setting.switchValues[1],
      AuxControlType.multiState => _normalizedMultiStateValues(
        setting,
      )[runtime.selectedIndex],
      AuxControlType.value => setting.singleValue,
    };
    return auxChannelPercentToUs(percent);
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

  Future<void> _loadSavedAuxRuntime(AppSettingsState settings) async {
    final saved = await _auxRuntimeStore.load();
    if (!mounted || saved.isEmpty) {
      return;
    }
    final ch3 = _runtimeFromSaved(settings, 2, saved[2]);
    final ch4 = _runtimeFromSaved(settings, 3, saved[3]);
    state = state.copyWith(
      ch3Runtime: ch3 ?? state.ch3Runtime,
      ch4Runtime: ch4 ?? state.ch4Runtime,
    );
  }

  /// 恢复控制页输入运行状态；控制循环尚未启动时不会发送控制数据。
  Future<void> _loadSavedInputRuntime() async {
    final saved = await _runtimeStore.loadInputState();
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      gyroEnabled: saved.gyroEnabled,
      throttleTrim: saved.throttleTrim,
      trim: saved.steeringTrim,
      sliderButtonsVisible: saved.sliderButtonsVisible,
    );
  }

  /// 保存陀螺仪与微调状态，存储异常不影响控制输出。
  Future<void> _saveInputRuntime() async {
    try {
      await _runtimeStore.saveInputState(
        StoredControlInputState(
          gyroEnabled: state.gyroEnabled,
          throttleTrim: state.throttleTrim,
          steeringTrim: state.trim,
          sliderButtonsVisible: state.sliderButtonsVisible,
        ),
      );
    } catch (_) {
      // 本地保存失败时仍保留当前页面中的控制状态。
    }
  }

  AuxChannelRuntimeState? _runtimeFromSaved(
    AppSettingsState settings,
    int channelIndex,
    StoredAuxChannelRuntime? saved,
  ) {
    if (saved == null) {
      return null;
    }
    final setting = _channelSettingAt(settings.channels, channelIndex);
    final values = _normalizedMultiStateValues(setting);
    return AuxChannelRuntimeState(
      controlType: setting.controlType,
      selectedIndex: saved.selectedIndex.clamp(0, values.length - 1),
      switchOn: saved.switchOn,
    );
  }

  Future<void> _saveAuxRuntime(
    int channelIndex,
    AuxChannelRuntimeState runtime,
  ) {
    return _auxRuntimeStore.saveChannel(
      channelIndex,
      StoredAuxChannelRuntime(
        selectedIndex: runtime.selectedIndex,
        switchOn: runtime.switchOn,
      ),
    );
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
      multiStateValues: const <double>[-100, 0, 100],
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

import 'dart:convert';

import 'aux_channel_value_rules.dart';
import 'gear_settings.dart';
import 'gyro_calibration_settings.dart';

/// 控制页手型布局；单手模式使用一个双轴区域同时控制方向和油门。
enum Handedness { singleRight, singleLeft, leftThrottle, rightThrottle }

enum ControlMode { fixedPosition, floating }

/// 体感输入覆盖的通道范围；是否启用由控制页陀螺仪开关决定。
enum GyroMode { directionOnly, throttleOnly, all }

/// 单通道体感模式下，剩余触控通道所在的操作区域。
enum GyroHandMode { left, right, dual }

enum BatteryType { oneCell, twoCell, threeCell, fourCell, other }

enum BackgroundMusicMode { defaultTrack, localTrack }

enum AuxiliaryFunction {
  none,
  headlight,
  warningLight,
  gearControl,
  gyro,
  brakeLight,
  reverseLight,
  leftSignal,
  rightSignal,
}

enum AuxControlType { disabled, switchControl, multiState, value }

class ChannelSetting {
  const ChannelSetting({
    required this.channelLabel,
    required this.title,
    required this.function,
    required this.displayName,
    required this.controlType,
    required this.switchValues,
    required this.multiStateValues,
    this.multiStateLabels = const <String>[],
    required this.singleValue,
    required this.lowPercent,
    required this.highPercent,
    required this.trimPercent,
    required this.reversed,
  });

  final String channelLabel;
  final String title;
  final AuxiliaryFunction function;
  final String displayName;
  final AuxControlType controlType;
  final List<double> switchValues;
  final List<double> multiStateValues;
  final List<String> multiStateLabels;
  final double singleValue;
  final double lowPercent;
  final double highPercent;
  final double trimPercent;
  final bool reversed;

  ChannelSetting copyWith({
    String? channelLabel,
    String? title,
    AuxiliaryFunction? function,
    String? displayName,
    AuxControlType? controlType,
    List<double>? switchValues,
    List<double>? multiStateValues,
    List<String>? multiStateLabels,
    double? singleValue,
    double? lowPercent,
    double? highPercent,
    double? trimPercent,
    bool? reversed,
  }) {
    return ChannelSetting(
      channelLabel: channelLabel ?? this.channelLabel,
      title: title ?? this.title,
      function: function ?? this.function,
      displayName: displayName ?? this.displayName,
      controlType: controlType ?? this.controlType,
      switchValues: switchValues ?? this.switchValues,
      multiStateValues: multiStateValues ?? this.multiStateValues,
      multiStateLabels: multiStateLabels ?? this.multiStateLabels,
      singleValue: singleValue ?? this.singleValue,
      lowPercent: lowPercent ?? this.lowPercent,
      highPercent: highPercent ?? this.highPercent,
      trimPercent: trimPercent ?? this.trimPercent,
      reversed: reversed ?? this.reversed,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'channelLabel': channelLabel,
      'title': title,
      'function': function.name,
      'displayName': displayName,
      'controlType': controlType.name,
      'switchValues': switchValues,
      'multiStateValues': multiStateValues,
      'multiStateLabels': normalizeAuxMultiStateLabels(
        multiStateLabels,
        stateCount: normalizeAuxMultiStateValues(multiStateValues).length,
      ),
      'singleValue': singleValue,
      'lowPercent': lowPercent,
      'highPercent': highPercent,
      'trimPercent': trimPercent,
      'reversed': reversed,
    };
  }

  factory ChannelSetting.fromJson(Map<String, Object?> json) {
    final function = AuxiliaryFunction.values.byName(
      json['function']! as String,
    );
    final lowPercent = (json['lowPercent']! as num).toDouble();
    final highPercent = (json['highPercent']! as num).toDouble();
    final trimPercent = (json['trimPercent']! as num).toDouble();
    final displayName =
        json['displayName'] as String? ??
        _defaultDisplayNameForChannelLabel(json['channelLabel']! as String);
    final controlType = _auxControlTypeFromJson(
      json['controlType'] as String?,
      legacyFunction: function,
    );
    final switchValues = normalizeAuxSwitchValues(
      _doubleListFromJson(
        json['switchValues'],
        fallback: <double>[highPercent, lowPercent],
      ),
    );
    final multiStateValues = normalizeAuxMultiStateValues(
      _doubleListFromJson(
        json['multiStateValues'],
        fallback: defaultAuxMultiStateValues,
      ),
    );
    final multiStateLabels = normalizeAuxMultiStateLabels(
      (json['multiStateLabels'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      stateCount: multiStateValues.length,
    );
    final singleValue = normalizeAuxChannelPercent(
      (json['singleValue'] as num?)?.toDouble() ?? trimPercent,
    );

    return ChannelSetting(
      channelLabel: json['channelLabel']! as String,
      title: json['title']! as String,
      function: function,
      displayName: displayName,
      controlType: controlType,
      switchValues: switchValues,
      multiStateValues: multiStateValues,
      multiStateLabels: multiStateLabels,
      singleValue: singleValue,
      lowPercent: lowPercent,
      highPercent: highPercent,
      trimPercent: trimPercent,
      reversed: json['reversed']! as bool,
    );
  }
}

class AppSettingsState {
  const AppSettingsState({
    required this.handedness,
    required this.controlMode,
    required this.gyroMode,
    required this.gyroHandMode,
    required this.gyroCalibration,
    required this.channels,
    required this.tankMixingEnabled,
    required this.trackMixLeft,
    required this.trackMixRight,
    required this.tankForwardPercent,
    required this.tankReversePercent,
    required this.tankLeftTurnPercent,
    required this.tankRightTurnPercent,
    required this.gearSettings,
    required this.lowVoltageEnabled,
    required this.batteryType,
    required this.minimumVoltage,
    required this.fullVoltage,
    required this.batteryAlertPercent,
    required this.batteryVoice,
    required this.batteryVibration,
    required this.lowSignalEnabled,
    required this.signalThreshold,
    required this.signalVoice,
    required this.signalVibration,
    required this.reconnectVoice,
    required this.reconnectVibration,
    required this.backgroundMusicMode,
    required this.backgroundMusicName,
  });

  final Handedness handedness;
  final ControlMode controlMode;
  final GyroMode gyroMode;
  final GyroHandMode gyroHandMode;
  final GyroCalibrationSettings gyroCalibration;
  final List<ChannelSetting> channels;
  final bool tankMixingEnabled;
  final double trackMixLeft;
  final double trackMixRight;
  final double tankForwardPercent;
  final double tankReversePercent;
  final double tankLeftTurnPercent;
  final double tankRightTurnPercent;
  final GearSettings gearSettings;
  final bool lowVoltageEnabled;
  final BatteryType batteryType;
  final double minimumVoltage;
  final double fullVoltage;
  final double batteryAlertPercent;
  final bool batteryVoice;
  final bool batteryVibration;
  final bool lowSignalEnabled;
  final double signalThreshold;
  final bool signalVoice;
  final bool signalVibration;
  final bool reconnectVoice;
  final bool reconnectVibration;
  final BackgroundMusicMode backgroundMusicMode;
  final String backgroundMusicName;

  factory AppSettingsState.defaults() {
    return AppSettingsState(
      handedness: Handedness.rightThrottle,
      controlMode: ControlMode.fixedPosition,
      gyroMode: GyroMode.throttleOnly,
      gyroHandMode: GyroHandMode.left,
      gyroCalibration: GyroCalibrationSettings.defaults,
      channels: const <ChannelSetting>[
        ChannelSetting(
          channelLabel: 'CH1',
          title: '油门',
          function: AuxiliaryFunction.none,
          displayName: 'CH1',
          controlType: AuxControlType.disabled,
          switchValues: <double>[100, -100],
          multiStateValues: defaultAuxMultiStateValues,
          singleValue: 0,
          lowPercent: -100,
          highPercent: 100,
          trimPercent: 0,
          reversed: false,
        ),
        ChannelSetting(
          channelLabel: 'CH2',
          title: '方向',
          function: AuxiliaryFunction.none,
          displayName: 'CH2',
          controlType: AuxControlType.disabled,
          switchValues: <double>[100, -100],
          multiStateValues: defaultAuxMultiStateValues,
          singleValue: 0,
          lowPercent: -100,
          highPercent: 100,
          trimPercent: 0,
          reversed: false,
        ),
        ChannelSetting(
          channelLabel: 'CH3',
          title: '辅助通道',
          function: AuxiliaryFunction.headlight,
          displayName: '辅助1',
          controlType: AuxControlType.switchControl,
          switchValues: <double>[100, -100],
          multiStateValues: defaultAuxMultiStateValues,
          singleValue: 0,
          lowPercent: -100,
          highPercent: 100,
          trimPercent: 0,
          reversed: false,
        ),
        ChannelSetting(
          channelLabel: 'CH4',
          title: '辅助通道',
          function: AuxiliaryFunction.warningLight,
          displayName: '辅助2',
          controlType: AuxControlType.switchControl,
          switchValues: <double>[100, -100],
          multiStateValues: defaultAuxMultiStateValues,
          singleValue: 0,
          lowPercent: -100,
          highPercent: 100,
          trimPercent: 0,
          reversed: false,
        ),
      ],
      tankMixingEnabled: false,
      trackMixLeft: 100,
      trackMixRight: 100,
      tankForwardPercent: 100,
      tankReversePercent: 100,
      tankLeftTurnPercent: 100,
      tankRightTurnPercent: 100,
      gearSettings: GearSettings.defaults,
      lowVoltageEnabled: true,
      batteryType: BatteryType.twoCell,
      minimumVoltage: 6.0,
      fullVoltage: 8.4,
      batteryAlertPercent: 15,
      batteryVoice: true,
      batteryVibration: true,
      lowSignalEnabled: true,
      signalThreshold: 30,
      signalVoice: true,
      signalVibration: false,
      reconnectVoice: true,
      reconnectVibration: false,
      backgroundMusicMode: BackgroundMusicMode.defaultTrack,
      backgroundMusicName: '默认',
    );
  }

  AppSettingsState copyWith({
    Handedness? handedness,
    ControlMode? controlMode,
    GyroMode? gyroMode,
    GyroHandMode? gyroHandMode,
    GyroCalibrationSettings? gyroCalibration,
    List<ChannelSetting>? channels,
    bool? tankMixingEnabled,
    double? trackMixLeft,
    double? trackMixRight,
    double? tankForwardPercent,
    double? tankReversePercent,
    double? tankLeftTurnPercent,
    double? tankRightTurnPercent,
    GearSettings? gearSettings,
    bool? lowVoltageEnabled,
    BatteryType? batteryType,
    double? minimumVoltage,
    double? fullVoltage,
    double? batteryAlertPercent,
    bool? batteryVoice,
    bool? batteryVibration,
    bool? lowSignalEnabled,
    double? signalThreshold,
    bool? signalVoice,
    bool? signalVibration,
    bool? reconnectVoice,
    bool? reconnectVibration,
    BackgroundMusicMode? backgroundMusicMode,
    String? backgroundMusicName,
  }) {
    return AppSettingsState(
      handedness: handedness ?? this.handedness,
      controlMode: controlMode ?? this.controlMode,
      gyroMode: gyroMode ?? this.gyroMode,
      gyroHandMode: gyroHandMode ?? this.gyroHandMode,
      gyroCalibration: gyroCalibration ?? this.gyroCalibration,
      channels: channels ?? this.channels,
      tankMixingEnabled: tankMixingEnabled ?? this.tankMixingEnabled,
      trackMixLeft: trackMixLeft ?? this.trackMixLeft,
      trackMixRight: trackMixRight ?? this.trackMixRight,
      tankForwardPercent: tankForwardPercent ?? this.tankForwardPercent,
      tankReversePercent: tankReversePercent ?? this.tankReversePercent,
      tankLeftTurnPercent: tankLeftTurnPercent ?? this.tankLeftTurnPercent,
      tankRightTurnPercent: tankRightTurnPercent ?? this.tankRightTurnPercent,
      gearSettings: gearSettings ?? this.gearSettings,
      lowVoltageEnabled: lowVoltageEnabled ?? this.lowVoltageEnabled,
      batteryType: batteryType ?? this.batteryType,
      minimumVoltage: minimumVoltage ?? this.minimumVoltage,
      fullVoltage: fullVoltage ?? this.fullVoltage,
      batteryAlertPercent: batteryAlertPercent ?? this.batteryAlertPercent,
      batteryVoice: batteryVoice ?? this.batteryVoice,
      batteryVibration: batteryVibration ?? this.batteryVibration,
      lowSignalEnabled: lowSignalEnabled ?? this.lowSignalEnabled,
      signalThreshold: signalThreshold ?? this.signalThreshold,
      signalVoice: signalVoice ?? this.signalVoice,
      signalVibration: signalVibration ?? this.signalVibration,
      reconnectVoice: reconnectVoice ?? this.reconnectVoice,
      reconnectVibration: reconnectVibration ?? this.reconnectVibration,
      backgroundMusicMode: backgroundMusicMode ?? this.backgroundMusicMode,
      backgroundMusicName: backgroundMusicName ?? this.backgroundMusicName,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'handedness': handedness.name,
      'controlMode': controlMode.name,
      'gyroMode': gyroMode.name,
      'gyroHandMode': gyroHandMode.name,
      'gyroCalibration': gyroCalibration.toJson(),
      'channels': channels
          .map((channel) => channel.toJson())
          .toList(growable: false),
      'tankMixingEnabled': tankMixingEnabled,
      'trackMixLeft': trackMixLeft,
      'trackMixRight': trackMixRight,
      'tankForwardPercent': tankForwardPercent,
      'tankReversePercent': tankReversePercent,
      'tankLeftTurnPercent': tankLeftTurnPercent,
      'tankRightTurnPercent': tankRightTurnPercent,
      'gearSettings': gearSettings.toJson(),
      'lowVoltageEnabled': lowVoltageEnabled,
      'batteryType': batteryType.name,
      'minimumVoltage': minimumVoltage,
      'fullVoltage': fullVoltage,
      'batteryAlertPercent': batteryAlertPercent,
      'batteryVoice': batteryVoice,
      'batteryVibration': batteryVibration,
      'lowSignalEnabled': lowSignalEnabled,
      'signalThreshold': signalThreshold,
      'signalVoice': signalVoice,
      'signalVibration': signalVibration,
      'reconnectVoice': reconnectVoice,
      'reconnectVibration': reconnectVibration,
      'backgroundMusicMode': backgroundMusicMode.name,
      'backgroundMusicName': backgroundMusicName,
    };
  }

  String toStorageString() => jsonEncode(toJson());

  factory AppSettingsState.fromStorageString(String raw) {
    return AppSettingsState.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  factory AppSettingsState.fromJson(Map<String, Object?> json) {
    return AppSettingsState(
      handedness: Handedness.values.byName(json['handedness']! as String),
      controlMode: ControlMode.values.byName(json['controlMode']! as String),
      gyroMode: _gyroModeFromStorage(json['gyroMode']! as String),
      gyroHandMode: _gyroHandModeFromStorage(json['gyroHandMode'] as String?),
      gyroCalibration: GyroCalibrationSettings.fromJson(
        json['gyroCalibration'],
      ),
      channels: (json['channels']! as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(ChannelSetting.fromJson)
          .map(_normalizePrimaryChannel)
          .toList(growable: false),
      tankMixingEnabled: json['tankMixingEnabled'] as bool? ?? false,
      trackMixLeft: (json['trackMixLeft'] as num?)?.toDouble() ?? 100,
      trackMixRight: (json['trackMixRight'] as num?)?.toDouble() ?? 100,
      tankForwardPercent:
          (json['tankForwardPercent'] as num?)?.toDouble() ?? 100,
      tankReversePercent:
          (json['tankReversePercent'] as num?)?.toDouble() ?? 100,
      tankLeftTurnPercent:
          (json['tankLeftTurnPercent'] as num?)?.toDouble() ?? 100,
      tankRightTurnPercent:
          (json['tankRightTurnPercent'] as num?)?.toDouble() ?? 100,
      gearSettings: GearSettings.fromJson(json['gearSettings']),
      lowVoltageEnabled: json['lowVoltageEnabled']! as bool,
      batteryType: _batteryTypeFromStorage(json['batteryType']! as String),
      minimumVoltage: (json['minimumVoltage']! as num).toDouble(),
      fullVoltage: (json['fullVoltage']! as num).toDouble(),
      batteryAlertPercent: (json['batteryAlertPercent']! as num).toDouble(),
      batteryVoice: json['batteryVoice']! as bool,
      batteryVibration: json['batteryVibration']! as bool,
      lowSignalEnabled: json['lowSignalEnabled']! as bool,
      signalThreshold: (json['signalThreshold']! as num).toDouble(),
      signalVoice: json['signalVoice']! as bool,
      signalVibration: json['signalVibration']! as bool,
      reconnectVoice: json['reconnectVoice']! as bool,
      reconnectVibration: json['reconnectVibration']! as bool,
      backgroundMusicMode: BackgroundMusicMode.values.byName(
        json['backgroundMusicMode']! as String,
      ),
      backgroundMusicName: json['backgroundMusicName']! as String,
    );
  }
}

AuxControlType _auxControlTypeFromJson(
  String? raw, {
  required AuxiliaryFunction legacyFunction,
}) {
  if (raw != null) {
    switch (raw) {
      case 'disabled':
      case 'switchControl':
      case 'multiState':
      case 'value':
        return AuxControlType.values.byName(raw);
    }
  }

  switch (legacyFunction) {
    case AuxiliaryFunction.none:
      return AuxControlType.disabled;
    case AuxiliaryFunction.headlight:
    case AuxiliaryFunction.warningLight:
      return AuxControlType.switchControl;
    case AuxiliaryFunction.gearControl:
      return AuxControlType.multiState;
    case AuxiliaryFunction.gyro:
      return AuxControlType.value;
    case AuxiliaryFunction.brakeLight:
    case AuxiliaryFunction.reverseLight:
    case AuxiliaryFunction.leftSignal:
    case AuxiliaryFunction.rightSignal:
      return AuxControlType.switchControl;
  }
}

List<double> _doubleListFromJson(
  Object? raw, {
  required List<double> fallback,
}) {
  final values = (raw as List<dynamic>?)
      ?.whereType<num>()
      .map((value) => value.toDouble())
      .toList(growable: true);
  if (values == null || values.isEmpty) {
    return List<double>.of(fallback);
  }
  return values;
}

String _defaultDisplayNameForChannelLabel(String channelLabel) {
  switch (channelLabel) {
    case 'CH3':
      return '辅助1';
    case 'CH4':
      return '辅助2';
    default:
      return channelLabel;
  }
}

ChannelSetting _normalizePrimaryChannel(ChannelSetting channel) {
  switch (channel.channelLabel) {
    case 'CH1':
      return channel.copyWith(title: '油门');
    case 'CH2':
      return channel.copyWith(title: '方向');
    default:
      return channel;
  }
}

BatteryType _batteryTypeFromStorage(String raw) {
  switch (raw) {
    case 'custom':
      return BatteryType.other;
    case 'oneCell':
    case 'twoCell':
    case 'threeCell':
    case 'fourCell':
    case 'other':
      return BatteryType.values.byName(raw);
  }
  return BatteryType.twoCell;
}

GyroMode _gyroModeFromStorage(String raw) {
  switch (raw) {
    case 'off':
      return GyroMode.throttleOnly;
    case 'directionOnly':
    case 'throttleOnly':
    case 'all':
      return GyroMode.values.byName(raw);
  }
  return GyroMode.throttleOnly;
}

/// 兼容旧版本尚未保存体感手型时的默认布局。
GyroHandMode _gyroHandModeFromStorage(String? raw) {
  switch (raw) {
    case 'left':
    case 'right':
    case 'dual':
      return GyroHandMode.values.byName(raw!);
  }
  return GyroHandMode.left;
}

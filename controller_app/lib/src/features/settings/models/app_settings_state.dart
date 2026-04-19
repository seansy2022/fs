import 'dart:convert';

enum Handedness { leftThrottle, rightThrottle }

enum ControlMode { fixedPosition, floating }

enum GyroMode { off, directionOnly, all }

enum BatteryType { twoCell, threeCell, custom }

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

class ChannelSetting {
  const ChannelSetting({
    required this.channelLabel,
    required this.title,
    required this.function,
    required this.lowPercent,
    required this.highPercent,
    required this.trimPercent,
    required this.reversed,
  });

  final String channelLabel;
  final String title;
  final AuxiliaryFunction function;
  final double lowPercent;
  final double highPercent;
  final double trimPercent;
  final bool reversed;

  ChannelSetting copyWith({
    String? channelLabel,
    String? title,
    AuxiliaryFunction? function,
    double? lowPercent,
    double? highPercent,
    double? trimPercent,
    bool? reversed,
  }) {
    return ChannelSetting(
      channelLabel: channelLabel ?? this.channelLabel,
      title: title ?? this.title,
      function: function ?? this.function,
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
      'lowPercent': lowPercent,
      'highPercent': highPercent,
      'trimPercent': trimPercent,
      'reversed': reversed,
    };
  }

  factory ChannelSetting.fromJson(Map<String, Object?> json) {
    return ChannelSetting(
      channelLabel: json['channelLabel']! as String,
      title: json['title']! as String,
      function: AuxiliaryFunction.values.byName(json['function']! as String),
      lowPercent: (json['lowPercent']! as num).toDouble(),
      highPercent: (json['highPercent']! as num).toDouble(),
      trimPercent: (json['trimPercent']! as num).toDouble(),
      reversed: json['reversed']! as bool,
    );
  }
}

class AppSettingsState {
  const AppSettingsState({
    required this.handedness,
    required this.controlMode,
    required this.gyroMode,
    required this.channels,
    required this.trackMixLeft,
    required this.trackMixRight,
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
  final List<ChannelSetting> channels;
  final double trackMixLeft;
  final double trackMixRight;
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
      gyroMode: GyroMode.directionOnly,
      channels: const <ChannelSetting>[
        ChannelSetting(
          channelLabel: 'CH1',
          title: '方向',
          function: AuxiliaryFunction.none,
          lowPercent: -100,
          highPercent: 100,
          trimPercent: 0,
          reversed: false,
        ),
        ChannelSetting(
          channelLabel: 'CH2',
          title: '油门',
          function: AuxiliaryFunction.none,
          lowPercent: -100,
          highPercent: 100,
          trimPercent: 0,
          reversed: false,
        ),
        ChannelSetting(
          channelLabel: 'CH3',
          title: '辅助通道',
          function: AuxiliaryFunction.headlight,
          lowPercent: -100,
          highPercent: 100,
          trimPercent: 0,
          reversed: false,
        ),
        ChannelSetting(
          channelLabel: 'CH4',
          title: '辅助通道',
          function: AuxiliaryFunction.warningLight,
          lowPercent: -100,
          highPercent: 100,
          trimPercent: 0,
          reversed: false,
        ),
      ],
      trackMixLeft: -70,
      trackMixRight: 50,
      lowVoltageEnabled: true,
      batteryType: BatteryType.twoCell,
      minimumVoltage: 6.2,
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
      backgroundMusicName: '默认背景音乐',
    );
  }

  AppSettingsState copyWith({
    Handedness? handedness,
    ControlMode? controlMode,
    GyroMode? gyroMode,
    List<ChannelSetting>? channels,
    double? trackMixLeft,
    double? trackMixRight,
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
      channels: channels ?? this.channels,
      trackMixLeft: trackMixLeft ?? this.trackMixLeft,
      trackMixRight: trackMixRight ?? this.trackMixRight,
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
      'channels': channels
          .map((channel) => channel.toJson())
          .toList(growable: false),
      'trackMixLeft': trackMixLeft,
      'trackMixRight': trackMixRight,
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
      gyroMode: GyroMode.values.byName(json['gyroMode']! as String),
      channels: (json['channels']! as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(ChannelSetting.fromJson)
          .toList(growable: false),
      trackMixLeft: (json['trackMixLeft']! as num).toDouble(),
      trackMixRight: (json['trackMixRight']! as num).toDouble(),
      lowVoltageEnabled: json['lowVoltageEnabled']! as bool,
      batteryType: BatteryType.values.byName(json['batteryType']! as String),
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

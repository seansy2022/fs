import '../constants.dart';
import '../types.dart';

class CurveState {
  const CurveState({required this.activeCurve, required this.curveValue});

  final String activeCurve;
  final int curveValue;

  CurveState copyWith({String? activeCurve, int? curveValue}) {
    return CurveState(
      activeCurve: activeCurve ?? this.activeCurve,
      curveValue: curveValue ?? this.curveValue,
    );
  }
}

const initialCurveState = CurveState(activeCurve: 'Steering', curveValue: 0);
const _copyWithUnset = Object();

class ControlMappingState {
  const ControlMappingState({
    required this.channel,
    required this.type,
    required this.action,
    required this.mode,
    required this.controlType,
    required this.availableStates,
    required this.selectedState,
    required this.functionType,
    required this.targetChannel,
    required this.mixingFunction,
    required this.mixingMode1,
    required this.mixingMode2,
    required this.mixingMode3,
  });

  final String channel;
  final String type;
  final String action;
  final String mode;
  final ControlType controlType;
  final List<String> availableStates;
  final String selectedState;
  final String functionType;
  final String? targetChannel;
  final String? mixingFunction;
  final String? mixingMode1;
  final String? mixingMode2;
  final String? mixingMode3;

  ControlMappingState copyWith({
    String? channel,
    String? type,
    String? action,
    String? mode,
    ControlType? controlType,
    List<String>? availableStates,
    String? selectedState,
    String? functionType,
    Object? targetChannel = _copyWithUnset,
    Object? mixingFunction = _copyWithUnset,
    Object? mixingMode1 = _copyWithUnset,
    Object? mixingMode2 = _copyWithUnset,
    Object? mixingMode3 = _copyWithUnset,
  }) {
    return ControlMappingState(
      channel: channel ?? this.channel,
      type: type ?? this.type,
      action: action ?? this.action,
      mode: mode ?? this.mode,
      controlType: controlType ?? this.controlType,
      availableStates: availableStates ?? this.availableStates,
      selectedState: selectedState ?? this.selectedState,
      functionType: functionType ?? this.functionType,
      targetChannel: targetChannel == _copyWithUnset
          ? this.targetChannel
          : targetChannel as String?,
      mixingFunction: mixingFunction == _copyWithUnset
          ? this.mixingFunction
          : mixingFunction as String?,
      mixingMode1: mixingMode1 == _copyWithUnset
          ? this.mixingMode1
          : mixingMode1 as String?,
      mixingMode2: mixingMode2 == _copyWithUnset
          ? this.mixingMode2
          : mixingMode2 as String?,
      mixingMode3: mixingMode3 == _copyWithUnset
          ? this.mixingMode3
          : mixingMode3 as String?,
    );
  }
}

ControlMappingState initialControlMappingState() {
  return const ControlMappingState(
    channel: 'CH11',
    type: '单击',
    action: '',
    mode: '翻转',
    controlType: ControlType.button,
    availableStates: <String>['单击', '双击', '三击', '长按'],
    selectedState: '单击',
    functionType: '',
    targetChannel: null,
    mixingFunction: null,
    mixingMode1: null,
    mixingMode2: null,
    mixingMode3: null,
  );
}

class EscSettingSnapshot {
  const EscSettingSnapshot({
    this.runningMode = 0,
    this.batteryType = 0,
    this.dragBrake = 0,
    this.receiverType = 0,
  });

  final int runningMode;
  final int batteryType;
  final int dragBrake;
  final int receiverType;

  EscSettingSnapshot copyWith({
    int? runningMode,
    int? batteryType,
    int? dragBrake,
    int? receiverType,
  }) {
    return EscSettingSnapshot(
      runningMode: runningMode ?? this.runningMode,
      batteryType: batteryType ?? this.batteryType,
      dragBrake: dragBrake ?? this.dragBrake,
      receiverType: receiverType ?? this.receiverType,
    );
  }
}

class FourWheelSteerSnapshot {
  const FourWheelSteerSnapshot({
    this.enabled = false,
    this.channel = 2,
    this.ratio = 100,
    this.mode = 0,
  });

  final bool enabled;
  final int channel;
  final int ratio;
  final int mode;

  FourWheelSteerSnapshot copyWith({
    bool? enabled,
    int? channel,
    int? ratio,
    int? mode,
  }) {
    return FourWheelSteerSnapshot(
      enabled: enabled ?? this.enabled,
      channel: channel ?? this.channel,
      ratio: ratio ?? this.ratio,
      mode: mode ?? this.mode,
    );
  }
}

class TrackMixingSnapshot {
  const TrackMixingSnapshot({
    this.enabled = false,
    this.forwardRatio = 100,
    this.backwardRatio = 100,
    this.leftRatio = 100,
    this.rightRatio = 100,
  });

  final bool enabled;
  final int forwardRatio;
  final int backwardRatio;
  final int leftRatio;
  final int rightRatio;

  TrackMixingSnapshot copyWith({
    bool? enabled,
    int? forwardRatio,
    int? backwardRatio,
    int? leftRatio,
    int? rightRatio,
  }) {
    return TrackMixingSnapshot(
      enabled: enabled ?? this.enabled,
      forwardRatio: forwardRatio ?? this.forwardRatio,
      backwardRatio: backwardRatio ?? this.backwardRatio,
      leftRatio: leftRatio ?? this.leftRatio,
      rightRatio: rightRatio ?? this.rightRatio,
    );
  }
}

class DriveMixingSnapshot {
  const DriveMixingSnapshot({
    this.enabled = false,
    this.channel = 2,
    this.frontRatio = 100,
    this.rearRatio = 100,
    this.mode = 0,
  });

  final bool enabled;
  final int channel;
  final int frontRatio;
  final int rearRatio;
  final int mode;

  DriveMixingSnapshot copyWith({
    bool? enabled,
    int? channel,
    int? frontRatio,
    int? rearRatio,
    int? mode,
  }) {
    return DriveMixingSnapshot(
      enabled: enabled ?? this.enabled,
      channel: channel ?? this.channel,
      frontRatio: frontRatio ?? this.frontRatio,
      rearRatio: rearRatio ?? this.rearRatio,
      mode: mode ?? this.mode,
    );
  }
}

class BrakeMixingSnapshot {
  const BrakeMixingSnapshot({
    this.mixingNo = 0,
    this.enabled = false,
    this.channel = 2,
    this.exponentEnabled = false,
    this.ratio = 100,
    this.curve = 0,
  });

  final int mixingNo;
  final bool enabled;
  final int channel;
  final bool exponentEnabled;
  final int ratio;
  final int curve;

  BrakeMixingSnapshot copyWith({
    int? mixingNo,
    bool? enabled,
    int? channel,
    bool? exponentEnabled,
    int? ratio,
    int? curve,
  }) {
    return BrakeMixingSnapshot(
      mixingNo: mixingNo ?? this.mixingNo,
      enabled: enabled ?? this.enabled,
      channel: channel ?? this.channel,
      exponentEnabled: exponentEnabled ?? this.exponentEnabled,
      ratio: ratio ?? this.ratio,
      curve: curve ?? this.curve,
    );
  }
}

class RcProtocolState {
  const RcProtocolState({
    required this.rawPayloadByCommand,
    required this.curveValues,
    this.escSetting = const EscSettingSnapshot(),
    this.fourWheelSteer = const FourWheelSteerSnapshot(),
    this.trackMixing = const TrackMixingSnapshot(),
    this.driveMixing = const DriveMixingSnapshot(),
    this.brakeMixing = const BrakeMixingSnapshot(),
  });

  final Map<int, List<int>> rawPayloadByCommand;
  final List<int> curveValues;
  final EscSettingSnapshot escSetting;
  final FourWheelSteerSnapshot fourWheelSteer;
  final TrackMixingSnapshot trackMixing;
  final DriveMixingSnapshot driveMixing;
  final BrakeMixingSnapshot brakeMixing;

  RcProtocolState copyWith({
    Map<int, List<int>>? rawPayloadByCommand,
    List<int>? curveValues,
    EscSettingSnapshot? escSetting,
    FourWheelSteerSnapshot? fourWheelSteer,
    TrackMixingSnapshot? trackMixing,
    DriveMixingSnapshot? driveMixing,
    BrakeMixingSnapshot? brakeMixing,
  }) {
    return RcProtocolState(
      rawPayloadByCommand: rawPayloadByCommand ?? this.rawPayloadByCommand,
      curveValues: curveValues ?? this.curveValues,
      escSetting: escSetting ?? this.escSetting,
      fourWheelSteer: fourWheelSteer ?? this.fourWheelSteer,
      trackMixing: trackMixing ?? this.trackMixing,
      driveMixing: driveMixing ?? this.driveMixing,
      brakeMixing: brakeMixing ?? this.brakeMixing,
    );
  }
}

class RcAppState {
  const RcAppState({
    required this.bluetooth,
    required this.telemetry,
    required this.channels,
    required this.models,
    required this.radioSettings,
    required this.mixingSettings,
    required this.curve,
    required this.controlMapping,
    Map<String, ControlMappingState>? controlMappings,
    required this.protocol,
  }) : _controlMappings = controlMappings;

  final BluetoothSettings bluetooth;
  final Telemetry telemetry;
  final List<ChannelState> channels;
  final List<Model> models;
  final RadioSettings radioSettings;
  final MixingSettings mixingSettings;
  final CurveState curve;
  final ControlMappingState controlMapping;
  final Map<String, ControlMappingState>? _controlMappings;
  Map<String, ControlMappingState> get controlMappings {
    final mappings = _controlMappings;
    if (mappings != null) return mappings;
    return <String, ControlMappingState>{
      controlMapping.channel: controlMapping,
    };
  }

  final RcProtocolState protocol;

  factory RcAppState.initial() {
    final controlMapping = initialControlMappingState();
    return RcAppState(
      bluetooth: const BluetoothSettings(devices: [], isScanning: false),
      telemetry: initialTelemetry,
      channels: _emptyChannels(),
      models: _emptyModels(),
      radioSettings: const RadioSettings(
        backlightTime: 0,
        idleAlarm: 0,
        atmosphereLight: false,
      ),
      mixingSettings: const MixingSettings(
        activeMode: '',
        enabled: false,
        ratio: 0,
        curve: 0,
        direction: '',
        selectedChannel: '',
      ),
      curve: initialCurveState,
      controlMapping: controlMapping,
      controlMappings: <String, ControlMappingState>{
        controlMapping.channel: controlMapping,
      },
      protocol: const RcProtocolState(
        rawPayloadByCommand: <int, List<int>>{},
        curveValues: <int>[0, 0, 0],
      ),
    );
  }

  RcAppState copyWith({
    BluetoothSettings? bluetooth,
    Telemetry? telemetry,
    List<ChannelState>? channels,
    List<Model>? models,
    RadioSettings? radioSettings,
    MixingSettings? mixingSettings,
    CurveState? curve,
    ControlMappingState? controlMapping,
    Map<String, ControlMappingState>? controlMappings,
    RcProtocolState? protocol,
  }) {
    return RcAppState(
      bluetooth: bluetooth ?? this.bluetooth,
      telemetry: telemetry ?? this.telemetry,
      channels: channels ?? this.channels,
      models: models ?? this.models,
      radioSettings: radioSettings ?? this.radioSettings,
      mixingSettings: mixingSettings ?? this.mixingSettings,
      curve: curve ?? this.curve,
      controlMapping: controlMapping ?? this.controlMapping,
      controlMappings: controlMappings ?? this.controlMappings,
      protocol: protocol ?? this.protocol,
    );
  }
}

List<ChannelState> _emptyChannels() {
  return List<ChannelState>.generate(11, (index) {
    final id = 'CH${index + 1}';
    return ChannelState(
      id: id,
      name: '',
      value: 0,
      lLimit: 0,
      rLimit: 0,
      reverse: false,
      offset: 0,
      dualRate: 0,
      failsafeActive: false,
      failsafeValue: 0,
    );
  });
}

List<Model> _emptyModels() {
  return List<Model>.generate(20, (index) {
    final no = (index + 1).toString().padLeft(2, '0');
    return Model(id: 'MOD$no', name: '', active: index == 1);
  });
}

sealed class RcAppIntent {
  const RcAppIntent();
}

class ChannelUpdatedIntent extends RcAppIntent {
  const ChannelUpdatedIntent({required this.id, required this.next});
  final String id;
  final ChannelState next;
}

class ChannelTravelUpdatedIntent extends RcAppIntent {
  const ChannelTravelUpdatedIntent({required this.id, required this.next});
  final String id;
  final ChannelState next;
}

class ChannelReverseUpdatedIntent extends RcAppIntent {
  const ChannelReverseUpdatedIntent({required this.id, required this.next});
  final String id;
  final ChannelState next;
}

class SubTrimUpdatedIntent extends RcAppIntent {
  const SubTrimUpdatedIntent({required this.id, required this.next});
  final String id;
  final ChannelState next;
}

class FailsafeUpdatedIntent extends RcAppIntent {
  const FailsafeUpdatedIntent({required this.id, required this.next});
  final String id;
  final ChannelState next;
}

class DualRateUpdatedIntent extends RcAppIntent {
  const DualRateUpdatedIntent({required this.id, required this.next});
  final String id;
  final ChannelState next;
}

class ModelSelectedIntent extends RcAppIntent {
  const ModelSelectedIntent(this.id);
  final String id;
}

class ModelRenamedIntent extends RcAppIntent {
  const ModelRenamedIntent({required this.id, required this.name});
  final String id;
  final String name;
}

class RadioSettingsUpdatedIntent extends RcAppIntent {
  const RadioSettingsUpdatedIntent(this.next);
  final RadioSettings next;
}

class MixingSettingsUpdatedIntent extends RcAppIntent {
  const MixingSettingsUpdatedIntent(this.next);
  final MixingSettings next;
}

class CurveSelectedIntent extends RcAppIntent {
  const CurveSelectedIntent(this.activeCurve);
  final String activeCurve;
}

class CurveValueUpdatedIntent extends RcAppIntent {
  const CurveValueUpdatedIntent(this.value);
  final int value;
}

class ControlMappingUpdatedIntent extends RcAppIntent {
  const ControlMappingUpdatedIntent(this.next);
  final ControlMappingState next;
}

class ControlMappingPreviewIntent extends RcAppIntent {
  const ControlMappingPreviewIntent(this.next);
  final ControlMappingState next;
}

enum Screen {
  dashboard,
  functions,
  channels,
  reverse,
  subTrim,
  dualRate,
  curve,
  controlMapping,
  modelSelection,
  failsafe,
  radioSettings,
  mixing,
  bluetooth,
}

class ChannelState {
  const ChannelState({
    required this.id,
    required this.name,
    required this.value,
    required this.lLimit,
    required this.rLimit,
    required this.reverse,
    required this.offset,
    required this.dualRate,
    required this.failsafeActive,
    required this.failsafeValue,
  });

  final String id;
  final String name;
  final int value;
  final int lLimit;
  final int rLimit;
  final bool reverse;
  final int offset;
  final int dualRate;
  final bool failsafeActive;
  final int failsafeValue;

  ChannelState copyWith({
    int? value,
    int? lLimit,
    int? rLimit,
    bool? reverse,
    int? offset,
    int? dualRate,
    bool? failsafeActive,
    int? failsafeValue,
  }) {
    return ChannelState(
      id: id,
      name: name,
      value: value ?? this.value,
      lLimit: lLimit ?? this.lLimit,
      rLimit: rLimit ?? this.rLimit,
      reverse: reverse ?? this.reverse,
      offset: offset ?? this.offset,
      dualRate: dualRate ?? this.dualRate,
      failsafeActive: failsafeActive ?? this.failsafeActive,
      failsafeValue: failsafeValue ?? this.failsafeValue,
    );
  }
}

class Model {
  const Model({required this.id, required this.name, required this.active});

  final String id;
  final String name;
  final bool active;

  Model copyWith({String? name, bool? active}) {
    return Model(
      id: id,
      name: name ?? this.name,
      active: active ?? this.active,
    );
  }
}

class MixingSettings {
  const MixingSettings({
    required this.activeMode,
    required this.enabled,
    required this.ratio,
    required this.curve,
    required this.direction,
    required this.selectedChannel,
    this.driveRatioSelectedSide = 'R',
  });

  final String activeMode;
  final bool enabled;
  final int ratio;
  final int curve;
  final String direction;
  final String selectedChannel;
  final String driveRatioSelectedSide;

  MixingSettings copyWith({
    String? activeMode,
    bool? enabled,
    int? ratio,
    int? curve,
    String? direction,
    String? selectedChannel,
    String? driveRatioSelectedSide,
  }) {
    return MixingSettings(
      activeMode: activeMode ?? this.activeMode,
      enabled: enabled ?? this.enabled,
      ratio: ratio ?? this.ratio,
      curve: curve ?? this.curve,
      direction: direction ?? this.direction,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      driveRatioSelectedSide:
          driveRatioSelectedSide ?? this.driveRatioSelectedSide,
    );
  }
}

class BluetoothDevice {
  const BluetoothDevice({
    required this.id,
    required this.name,
    required this.mac,
    required this.connected,
    required this.type,
    required this.signal,
  });

  final int id;
  final String name;
  final String mac;
  final bool connected;
  final String type;
  final int signal;

  BluetoothDevice copyWith({bool? connected, int? signal}) {
    return BluetoothDevice(
      id: id,
      name: name,
      mac: mac,
      connected: connected ?? this.connected,
      type: type,
      signal: signal ?? this.signal,
    );
  }
}

class BluetoothSettings {
  const BluetoothSettings({
    required this.devices,
    required this.isScanning,
    this.isConnecting = false,
    this.isConnected = false,
    this.connectedDeviceMac,
    this.connectingDeviceMac,
    this.connectingStartedAt,
    this.errorMessage,
  });

  final List<BluetoothDevice> devices;
  final bool isScanning;
  final bool isConnecting;
  final bool isConnected;
  final String? connectedDeviceMac;
  final String? connectingDeviceMac;
  final DateTime? connectingStartedAt;
  final String? errorMessage;

  BluetoothSettings copyWith({
    List<BluetoothDevice>? devices,
    bool? isScanning,
    bool? isConnecting,
    bool? isConnected,
    String? connectedDeviceMac,
    String? connectingDeviceMac,
    DateTime? connectingStartedAt,
    String? errorMessage,
    bool clearConnectedDeviceMac = false,
    bool clearConnectingDeviceMac = false,
    bool clearConnectingStartedAt = false,
    bool clearErrorMessage = false,
  }) {
    return BluetoothSettings(
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      connectedDeviceMac: clearConnectedDeviceMac
          ? null
          : connectedDeviceMac ?? this.connectedDeviceMac,
      connectingDeviceMac: clearConnectingDeviceMac
          ? null
          : connectingDeviceMac ?? this.connectingDeviceMac,
      connectingStartedAt: clearConnectingStartedAt
          ? null
          : connectingStartedAt ?? this.connectingStartedAt,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class RadioSettings {
  const RadioSettings({
    required this.backlightTime,
    required this.idleAlarm,
    required this.atmosphereLight,
  });

  final int backlightTime;
  final int idleAlarm;
  final bool atmosphereLight;

  RadioSettings copyWith({
    int? backlightTime,
    int? idleAlarm,
    bool? atmosphereLight,
  }) {
    return RadioSettings(
      backlightTime: backlightTime ?? this.backlightTime,
      idleAlarm: idleAlarm ?? this.idleAlarm,
      atmosphereLight: atmosphereLight ?? this.atmosphereLight,
    );
  }
}

class Telemetry {
  const Telemetry({
    required this.txVoltage,
    required this.rxVoltage,
    required this.signalStrength,
    required this.latency,
  });

  final double txVoltage;
  final double rxVoltage;
  final int signalStrength;
  final double latency;

  Telemetry copyWith({
    double? txVoltage,
    double? rxVoltage,
    int? signalStrength,
    double? latency,
  }) {
    return Telemetry(
      txVoltage: txVoltage ?? this.txVoltage,
      rxVoltage: rxVoltage ?? this.rxVoltage,
      signalStrength: signalStrength ?? this.signalStrength,
      latency: latency ?? this.latency,
    );
  }
}

enum ControlType { button, knob, threeWaySwitch, latchSwitch, wheel, trigger }

enum ControlState {
  singleClick,
  doubleClick,
  tripleClick,
  longPress,
  position0,
  position1,
  position2,
  position3,
  forward,
  backward,
  neutral,
}

enum FunctionType {
  none,
  channelOutput,
  mixingSwitch,
  trimSteering,
  trimThrottle,
  ratioSteering,
  ratioThrottle,
  ratio4WS,
  ratioDrive,
  ratioBrake,
  deviceFunction,
  mixingOnOff,
}

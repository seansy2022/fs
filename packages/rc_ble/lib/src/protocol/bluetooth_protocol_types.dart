enum BluetoothCommand {
  channelReverse(0x11),
  channelTravel(0x12),
  subTrim(0x13),
  dualRate(0x14),
  curve(0x15),
  fourWheelSteer(0x16),
  failsafe(0x17),
  escSetting(0x18),
  modelSwitch(0x19),
  trackMixing(0x1A),
  driveMixing(0x1B),
  brakeMixing(0x1C),
  controlMapping(0x1D),
  systemSetting(0x1E),
  channelDisplay(0xA1),
  telemetryDisplay(0xA2),
  passthrough(0xA3);

  const BluetoothCommand(this.id);
  final int id;

  static BluetoothCommand? fromId(int id) {
    for (final cmd in values) {
      if (cmd.id == id) return cmd;
    }
    return null;
  }
}

class AckResult {
  const AckResult({required this.code});

  final int code;
  bool get isSuccess => code == 0x20;
}

class ChannelSnapshot {
  const ChannelSnapshot({required this.values});

  final List<int> values;
}

class SensorValue {
  const SensorValue({
    required this.sensorType,
    required this.sensorId,
    required this.rawValue,
  });

  final int sensorType;
  final int sensorId;
  final int rawValue;
}

class TelemetryPacket {
  const TelemetryPacket({required this.values});

  final List<SensorValue> values;
}

class PassthroughPacket {
  const PassthroughPacket({required this.payload});

  final List<int> payload;
}

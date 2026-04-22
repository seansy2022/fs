import 'bluetooth_frame.dart';
import 'bluetooth_protocol_types.dart';

BluetoothFrame buildWriteFrame({
  required int seq,
  required BluetoothCommand command,
  required List<int> payload,
}) {
  final len = payload.length > bluetoothDataLength
      ? bluetoothDataLength
      : payload.length;
  return BluetoothFrame(
    seq: seq,
    command: command.id,
    length: len,
    data: payload,
  );
}

BluetoothFrame buildReadFrame({
  required int seq,
  required BluetoothCommand command,
}) {
  return BluetoothFrame(
    seq: seq,
    command: command.id,
    length: 0,
    data: const [],
  );
}

AckResult? parseAck(BluetoothFrame frame) {
  if (frame.length < 1) return null;
  return AckResult(code: frame.data.first);
}

ChannelSnapshot? parseChannelDisplay(BluetoothFrame frame) {
  if (frame.command != BluetoothCommand.channelDisplay.id) return null;
  if (frame.length < 22) return null;
  final values = <int>[];
  for (var i = 0; i < 22; i += 2) {
    values.add(_decodeChannelWord(frame.data[i], frame.data[i + 1]));
  }
  return ChannelSnapshot(values: values);
}

TelemetryPacket? parseTelemetryDisplay(BluetoothFrame frame) {
  if (frame.command != BluetoothCommand.telemetryDisplay.id) return null;
  if (frame.length < 4) return const TelemetryPacket(values: []);
  final values = <SensorValue>[];
  final max = frame.length > bluetoothDataLength
      ? bluetoothDataLength
      : frame.length;
  // Some firmware revisions send A2 as fixed fields:
  // [txHigh, txLow, rxHigh, rxLow, rssi, ...]
  // instead of [sensorType, sensorId, valueLow, valueHigh] tuples.
  final looksLikeFixedLayout =
      max >= 5 &&
      (frame.data[0] == 0x00 || frame.data[0] == 0x01) &&
      frame.data[1] > 0x10;
  if (looksLikeFixedLayout) {
    final txRaw = _decodePwmWord(frame.data[0], frame.data[1]);
    final rxRaw = _decodePwmWord(frame.data[2], frame.data[3]);
    final rssiRaw = frame.data[4] & 0xFF;
    values.add(SensorValue(sensorType: 0x7F, sensorId: 0x01, rawValue: txRaw));
    values.add(SensorValue(sensorType: 0x03, sensorId: 0x01, rawValue: rxRaw));
    values.add(
      SensorValue(sensorType: 0xFC, sensorId: 0x01, rawValue: rssiRaw),
    );
    return TelemetryPacket(values: values);
  }
  for (var i = 0; i + 3 < max; i += 4) {
    final raw = (frame.data[i + 2] & 0xFF) | ((frame.data[i + 3] & 0xFF) << 8);
    values.add(
      SensorValue(
        sensorType: frame.data[i],
        sensorId: frame.data[i + 1],
        rawValue: raw,
      ),
    );
  }
  return TelemetryPacket(values: values);
}

PassthroughPacket? parsePassthrough(BluetoothFrame frame) {
  if (frame.command != BluetoothCommand.passthrough.id) return null;
  final len = frame.length > bluetoothDataLength
      ? bluetoothDataLength
      : frame.length;
  return PassthroughPacket(payload: frame.data.sublist(0, len));
}

int _decodeChannelWord(int first, int second) {
  return (first & 0xFF) | ((second & 0xFF) << 8);
}

int _decodePwmWord(int first, int second) {
  final be = ((first & 0xFF) << 8) | (second & 0xFF);
  final le = ((second & 0xFF) << 8) | (first & 0xFF);
  final bePlausible = be >= 800 && be <= 2200;
  final lePlausible = le >= 800 && le <= 2200;
  if (bePlausible && !lePlausible) return be;
  if (lePlausible && !bePlausible) return le;
  return be;
}

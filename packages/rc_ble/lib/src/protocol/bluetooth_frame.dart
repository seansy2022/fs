import 'bluetooth_crc8.dart';

const bluetoothFrameLength = 30;
const bluetoothDataLength = 24;
const bluetoothFrameHead = 0xA5;
const bluetoothFrameTail = 0x5A;

class BluetoothFrame {
  const BluetoothFrame({
    required this.seq,
    required this.command,
    required this.length,
    required this.data,
  });

  final int seq;
  final int command;
  final int length;
  final List<int> data;

  bool get isLengthValid => length >= 0 && length <= bluetoothDataLength;

  List<int> toBytes() {
    final payload = _paddedData(data);
    final body = [seq & 0xFF, command & 0xFF, length & 0xFF, ...payload];
    final crc = calculateBluetoothCrc8(body);
    return [bluetoothFrameHead, ...body, crc, bluetoothFrameTail];
  }

  static BluetoothFrame? tryParse(List<int> bytes) {
    if (bytes.length != bluetoothFrameLength) return null;
    if (bytes.first != bluetoothFrameHead || bytes.last != bluetoothFrameTail) {
      return null;
    }
    final seq = bytes[1];
    final cmd = bytes[2];
    final len = bytes[3];
    final data = bytes.sublist(4, 28);
    final expected = calculateBluetoothCrc8([seq, cmd, len, ...data]);
    if (expected != bytes[28]) return null;
    return BluetoothFrame(seq: seq, command: cmd, length: len, data: data);
  }

  static List<int> _paddedData(List<int> source) {
    final out = List<int>.filled(bluetoothDataLength, 0);
    final max = source.length > bluetoothDataLength
        ? bluetoothDataLength
        : source.length;
    for (var i = 0; i < max; i++) {
      out[i] = source[i] & 0xFF;
    }
    return out;
  }
}

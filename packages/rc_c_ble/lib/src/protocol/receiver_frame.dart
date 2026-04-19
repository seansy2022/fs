import 'receiver_checksum16.dart';

class ReceiverFrame {
  const ReceiverFrame({required this.command, required this.data});

  static const int head = 0xFA;
  static const int minimumLength = 5;

  final int command;
  final List<int> data;

  int get length => data.length + minimumLength;

  List<int> toBytes() {
    final body = <int>[head, length & 0xFF, command & 0xFF, ...data];
    final checksum = calculateReceiverChecksum16(body);
    return <int>[...body, (checksum >> 8) & 0xFF, checksum & 0xFF];
  }

  static ReceiverFrame? tryParse(List<int> bytes) {
    if (bytes.length < minimumLength) {
      return null;
    }
    if (bytes.first != head) {
      return null;
    }
    final expectedLength = bytes[1] & 0xFF;
    if (expectedLength != bytes.length) {
      return null;
    }
    final body = bytes.sublist(0, bytes.length - 2);
    final checksum =
        ((bytes[bytes.length - 2] & 0xFF) << 8) | (bytes.last & 0xFF);
    if (calculateReceiverChecksum16(body) != checksum) {
      return null;
    }
    return ReceiverFrame(
      command: bytes[2] & 0xFF,
      data: bytes.sublist(3, bytes.length - 2),
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/src/transport/flutter_blue_receiver_transport.dart';

void main() {
  test('0x07、0x08 与 0x13 同帧回显应交给协议层', () {
    expect(shouldUseReceiverEchoAsProtocolReply(0x07), isTrue);
    expect(shouldUseReceiverEchoAsProtocolReply(0x08), isTrue);
    expect(shouldUseReceiverEchoAsProtocolReply(0x13), isTrue);
    expect(shouldUseReceiverEchoAsProtocolReply(0x02), isFalse);
  });
}

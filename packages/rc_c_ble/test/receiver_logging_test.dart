import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/src/transport/receiver_logging.dart';

void main() {
  test('transmittedBytes 打印发送长度和十六进制数据', () {
    final logs = <String>[];

    runZoned(
      () => ReceiverLogging.transmittedBytes(const <int>[
        0xFA,
        0x01,
        0x0A,
        0xFF,
      ], scope: 'BleTest'),
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, message) => logs.add(message),
      ),
    );

    expect(logs, <String>['[BleTest] 📱 tx bytes(4) FA 01 0A FF']);
  });
}

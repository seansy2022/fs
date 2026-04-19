import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  test('mock transport emits a virtual device in scan results', () async {
    final transport = MockProtocolLinkTransport();
    addTearDown(transport.dispose);

    final first = transport.scanResults.first;
    await transport.startScan();
    final devices = await first;

    expect(devices, hasLength(1));
    expect(devices.first.remoteId, 'MOCK_RC_001');
    expect(devices.first.name, 'Mock RC MG11');
  });

  test(
    'mock transport responds to read/write config commands by protocol',
    () async {
      final transport = MockProtocolLinkTransport();
      addTearDown(transport.dispose);

      final readRequest = buildReadFrame(
        seq: 1,
        command: BluetoothCommand.channelReverse,
      ).toBytes();
      final readFuture = _waitFrame(
        transport.incomingBytes,
        BluetoothCommand.channelReverse.id,
      );
      await transport.send(readRequest);
      final readFrame = await readFuture;
      expect(readFrame.length, 11);
      expect(readFrame.data.sublist(0, 11), List<int>.filled(11, 0));

      final payload = <int>[1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1];
      final writeFuture = _waitFrame(
        transport.incomingBytes,
        BluetoothCommand.channelReverse.id,
      );
      await transport.send(
        buildWriteFrame(
          seq: 2,
          command: BluetoothCommand.channelReverse,
          payload: payload,
        ).toBytes(),
      );
      final ack = await writeFuture;
      expect(ack.length, 1);
      expect(ack.data.first, 0x20);

      final verifyFuture = _waitFrame(
        transport.incomingBytes,
        BluetoothCommand.channelReverse.id,
      );
      await transport.send(readRequest);
      final verify = await verifyFuture;
      expect(verify.length, payload.length);
      expect(verify.data.sublist(0, payload.length), payload);
    },
  );

  test('mock transport pushes A1/A2 telemetry frames after connect', () async {
    final transport = MockProtocolLinkTransport();
    addTearDown(transport.dispose);

    final seen = <int>{};
    final sub = transport.incomingBytes.listen((bytes) {
      final frame = BluetoothFrame.tryParse(bytes);
      if (frame != null) {
        seen.add(frame.command);
      }
    });
    addTearDown(sub.cancel);

    await transport.connect('MOCK_RC_001');
    await Future<void>.delayed(const Duration(milliseconds: 900));

    expect(seen, contains(BluetoothCommand.channelDisplay.id));
    expect(seen, contains(BluetoothCommand.telemetryDisplay.id));
  });
}

Future<BluetoothFrame> _waitFrame(Stream<List<int>> stream, int command) {
  return stream
      .map(BluetoothFrame.tryParse)
      .where((frame) => frame != null)
      .cast<BluetoothFrame>()
      .firstWhere((frame) => frame.command == command)
      .timeout(const Duration(seconds: 1));
}

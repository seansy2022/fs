import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ble/rc_ble.dart';

class FakeProtocolChannel implements BluetoothProtocolChannel {
  final StreamController<List<int>> _input = StreamController.broadcast();
  List<int>? lastSent;

  @override
  Stream<List<int>> get bytes => _input.stream;

  @override
  Future<void> send(List<int> bytes) async {
    lastSent = bytes;
  }

  void pushFrame(BluetoothFrame frame) {
    _input.add(frame.toBytes());
  }

  Future<void> dispose() async {
    await _input.close();
  }
}

void main() {
  test('writeCommand completes on ack frame', () async {
    final ch = FakeProtocolChannel();
    final client = BluetoothProtocolClient(channel: ch);
    addTearDown(() async {
      await client.dispose();
      await ch.dispose();
    });

    final task = client.writeCommand(BluetoothCommand.curve, const [0x01]);
    await Future<void>.delayed(Duration.zero);
    final sent = BluetoothFrame.tryParse(ch.lastSent!);
    ch.pushFrame(
      BluetoothFrame(
        seq: sent!.seq,
        command: sent.command,
        length: 1,
        data: const [0x20],
      ),
    );
    final ack = await task;
    expect(ack.isSuccess, true);
  });

  test('channel stream receives A1 frames', () async {
    final ch = FakeProtocolChannel();
    final client = BluetoothProtocolClient(channel: ch);
    addTearDown(() async {
      await client.dispose();
      await ch.dispose();
    });

    final wait = client.channelStream.first;
    final data = List<int>.filled(24, 0);
    data[0] = 0x03;
    data[1] = 0xE8;
    ch.pushFrame(
      BluetoothFrame(
        seq: 1,
        command: BluetoothCommand.channelDisplay.id,
        length: 22,
        data: data,
      ),
    );
    final packet = await wait;
    expect(packet.values.first, 1000);
  });

  test('readCommandWithPayload sends payload and waits data frame', () async {
    final ch = FakeProtocolChannel();
    final client = BluetoothProtocolClient(channel: ch);
    addTearDown(() async {
      await client.dispose();
      await ch.dispose();
    });

    final task = client.readCommandWithPayload(
      BluetoothCommand.controlMapping,
      const [0, 2],
    );
    await Future<void>.delayed(Duration.zero);
    final sent = BluetoothFrame.tryParse(ch.lastSent!);
    expect(sent, isNotNull);
    expect(sent!.command, BluetoothCommand.controlMapping.id);
    expect(sent.length, 2);
    expect(sent.data[1], 2);
    ch.pushFrame(
      BluetoothFrame(
        seq: sent.seq,
        command: sent.command,
        length: 9,
        data: const [0, 2, 1, 0, 0, 1, 2, 0, 2],
      ),
    );
    final frame = await task;
    expect(frame.length, 9);
    expect(frame.command, BluetoothCommand.controlMapping.id);
  });
}

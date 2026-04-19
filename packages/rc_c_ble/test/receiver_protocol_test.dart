import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ble/rc_ble.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_c_ble/src/protocol/receiver_checksum16.dart';
import 'package:rc_c_ble/src/protocol/receiver_frame_parser.dart';
import 'package:rc_c_ble/src/protocol/receiver_protocol_codec.dart';

void main() {
  test('checksum16 sums all bytes into a 16-bit value', () {
    final checksum = calculateReceiverChecksum16(const [
      0xFA,
      0x0D,
      0x01,
      0x00,
      0x00,
    ]);
    expect(checksum, 0x0108);
  });

  test('receiver frame round-trips through parser', () {
    final frame = ReceiverFrame(
      command: ReceiverCommand.receiverInfo.id,
      data: List<int>.filled(8, 0),
    );
    final parser = ReceiverFrameParser();
    final parsed = parser.addChunk(frame.toBytes());
    expect(parsed, hasLength(1));
    expect(parsed.single.command, frame.command);
    expect(parsed.single.data, frame.data);
  });

  test('parses receiver info response', () {
    final frame = ReceiverFrame(
      command: ReceiverCommand.receiverInfo.id,
      data: const [0x01, 0x02, 0x03, 0x04, 0x10, 0x20, 88, 0],
    );
    final info = parseReceiverInfoResponse(frame, remoteId: 'test-id');
    expect(info.remoteId, 'test-id');
    expect(info.rfmIdHex, '01020304');
    expect(info.productModelCode, 0x1020);
    expect(info.batteryLevel, 88);
  });

  test('parses failsafe response', () {
    final frame = ReceiverFrame(
      command: ReceiverCommand.readFailsafe.id,
      data: const [0xAA, 0xBB, 0xCC, 0xDD, 0x05, 0xDC, 0x00, 0x00],
    );
    final config = parseFailsafeResponse(frame);
    expect(config.throttleUs, 1500);
    expect(config.steeringUs, 0);
    expect(config.steeringHold, isTrue);
  });

  test('client upgrade flow yields progress until completion', () async {
    final transport = _FakeTransport();
    final client = ReceiverBleClient(transport: transport);
    transport.onSend = (bytes) {
      final frame = ReceiverFrame.tryParse(bytes)!;
      if (frame.command == ReceiverCommand.receiverInfo.id) {
        transport.emit(
          ReceiverFrame(
            command: ReceiverCommand.receiverInfo.id,
            data: const [0x11, 0x22, 0x33, 0x44, 0x01, 0x02, 95, 0],
          ).toBytes(),
        );
      } else if (frame.command == ReceiverCommand.startUpgradeBoot.id) {
        transport.emit(
          ReceiverFrame(
            command: ReceiverCommand.startUpgradeBoot.id,
            data: const [0x11, 0x22, 0x33, 0x44, 1, 0, 0, 0],
          ).toBytes(),
        );
      } else if (frame.command == ReceiverCommand.setUpgradeLength.id) {
        transport.emit(
          ReceiverFrame(
            command: ReceiverCommand.setUpgradeLength.id,
            data: const [0, 0, 0, 48, 1, 0, 0, 0],
          ).toBytes(),
        );
      } else if (frame.command == ReceiverCommand.sendUpgradeChunk.id) {
        final seq = frame.data.first;
        transport.emit(
          ReceiverFrame(
            command: ReceiverCommand.sendUpgradeChunk.id,
            data: <int>[seq, seq == 1 ? 2 : 1],
          ).toBytes(),
        );
      }
    };

    await client.connect('dev-1');
    await client.readReceiverInfo();

    final progress = await client
        .startUpgrade(
          Uint8List.fromList(List<int>.generate(48, (index) => index)),
        )
        .toList();
    expect(progress.last.stage, ReceiverUpgradeStage.completed);
    expect(progress.last.sentChunks, 2);
  });
}

class _FakeTransport implements LinkTransport {
  final StreamController<List<int>> _incomingCtrl =
      StreamController<List<int>>.broadcast();
  final StreamController<List<BluetoothScanDevice>> _scanCtrl =
      StreamController<List<BluetoothScanDevice>>.broadcast();

  void Function(List<int> bytes)? onSend;

  @override
  LinkType get type => LinkType.ble;

  @override
  Stream<List<int>> get incomingBytes => _incomingCtrl.stream;

  @override
  Stream<List<BluetoothScanDevice>> get scanResults => _scanCtrl.stream;

  @override
  Future<void> connect(String remoteId) async {}

  @override
  Future<void> disconnect(String remoteId) async {}

  void emit(List<int> bytes) {
    scheduleMicrotask(() => _incomingCtrl.add(bytes));
  }

  @override
  Future<void> send(List<int> bytes) async {
    onSend?.call(bytes);
  }

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}
}

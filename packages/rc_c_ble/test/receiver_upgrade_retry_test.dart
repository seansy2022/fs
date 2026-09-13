import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

void main() {
  test('0x13 首次超时后重试并继续升级', () async {
    final transport = _UpgradeFakeTransport();
    final client = ReceiverBleClient(
      transport: transport,
      requestTimeout: const Duration(milliseconds: 5),
      skipBootUpgradeForDebug: true,
    );
    var lengthRequests = 0;
    transport.onSend = (frame) {
      if (frame.command == ReceiverCommand.receiverInfo.id) {
        transport.emit(_receiverInfoResponse());
      } else if (frame.command == ReceiverCommand.setUpgradeLength.id) {
        lengthRequests++;
        if (lengthRequests == 2) {
          transport.emit(_upgradeLengthResponse());
        }
      } else if (frame.command == ReceiverCommand.sendUpgradeChunk.id) {
        transport.emit(_upgradeChunkCompletedResponse(frame));
      }
    };

    try {
      await client.connect('dev-1');
      await client.readReceiverInfo();
      final progress = await client
          .startUpgrade(Uint8List.fromList(List<int>.filled(23, 1)))
          .toList();

      expect(lengthRequests, 2);
      expect(progress.last.stage, ReceiverUpgradeStage.completed);
    } finally {
      await client.dispose();
      await transport.dispose();
    }
  });

  test('0x13 连续三次超时后结束升级', () async {
    final transport = _UpgradeFakeTransport();
    final client = ReceiverBleClient(
      transport: transport,
      requestTimeout: const Duration(milliseconds: 5),
      skipBootUpgradeForDebug: true,
    );
    var lengthRequests = 0;
    transport.onSend = (frame) {
      if (frame.command == ReceiverCommand.receiverInfo.id) {
        transport.emit(_receiverInfoResponse());
      } else if (frame.command == ReceiverCommand.setUpgradeLength.id) {
        lengthRequests++;
      }
    };

    try {
      await client.connect('dev-1');
      await client.readReceiverInfo();
      final progress = await client
          .startUpgrade(Uint8List.fromList(List<int>.filled(23, 1)))
          .toList();

      expect(lengthRequests, 3);
      expect(progress.last.stage, ReceiverUpgradeStage.failed);
      expect(progress.last.message, contains('Timed out'));
    } finally {
      await client.dispose();
      await transport.dispose();
    }
  });
}

ReceiverFrame _receiverInfoResponse() {
  return ReceiverFrame(
    command: ReceiverCommand.receiverInfo.id,
    data: const [0x11, 0x22, 0x33, 0x44, 0x01, 0x02, 95, 0],
  );
}

ReceiverFrame _upgradeLengthResponse() {
  return ReceiverFrame(
    command: ReceiverCommand.setUpgradeLength.id,
    data: const [0, 0, 0, 23, 1, 0, 0, 0],
  );
}

ReceiverFrame _upgradeChunkCompletedResponse(ReceiverFrame request) {
  return ReceiverFrame(
    command: ReceiverCommand.sendUpgradeChunk.id,
    data: [request.data[0], request.data[1], 2],
  );
}

class _UpgradeFakeTransport implements ReceiverLinkTransport {
  final _incoming = StreamController<List<int>>.broadcast(sync: true);
  final _scan = StreamController<List<BluetoothScanDevice>>.broadcast();
  final _adapter = StreamController<AdapterState>.broadcast();
  final _connection = StreamController<ReceiverLinkConnectionEvent>.broadcast();

  void Function(ReceiverFrame frame)? onSend;

  @override
  ReceiverLinkType get type => ReceiverLinkType.ble;

  @override
  AdapterState get currentAdapterState => AdapterState.on;

  @override
  Stream<AdapterState> get adapterState => _adapter.stream;

  @override
  Stream<ReceiverLinkConnectionEvent> get connectionEvents =>
      _connection.stream;

  @override
  Stream<List<int>> get incomingBytes => _incoming.stream;

  @override
  Stream<List<BluetoothScanDevice>> get scanResults => _scan.stream;

  @override
  Future<void> connect(String remoteId) async {}

  @override
  Future<void> disconnect(String remoteId) async {}

  @override
  Future<int> readRssi(String remoteId) async => -60;

  @override
  Future<void> send(
    List<int> bytes, {
    bool preferWithoutResponse = false,
  }) async {
    final frame = ReceiverFrame.tryParse(bytes);
    if (frame != null) onSend?.call(frame);
  }

  @override
  Future<void> startScan({
    List<String>? withRemoteIds,
    Duration? timeout,
  }) async {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<bool> turnOnAdapter() async => true;

  void emit(ReceiverFrame frame) => _incoming.add(frame.toBytes());

  Future<void> dispose() async {
    await _incoming.close();
    await _scan.close();
    await _adapter.close();
    await _connection.close();
  }
}

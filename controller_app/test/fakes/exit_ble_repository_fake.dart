import 'dart:async';
import 'dart:typed_data';

import 'package:rc_c_ble/rc_c_ble.dart';

class ExitBleRepositoryFake implements ReceiverRepository {
  ExitBleRepositoryFake({this.throwOnExit = false});

  final bool throwOnExit;
  int exitBleModeCalls = 0;
  int disconnectCalls = 0;
  ReceiverConnectionState _connectionState = ReceiverConnectionState.connected;
  final _connectionCtrl = StreamController<ReceiverConnectionState>.broadcast();

  @override
  ReceiverConnectionState get connectionState => _connectionState;

  @override
  Stream<AdapterState> get adapterStateStream async* {
    yield AdapterState.on;
  }

  @override
  Stream<int?> get connectedRssiStream async* {
    yield null;
  }

  @override
  Stream<ReceiverConnectionState> get connectionStateStream async* {
    yield ReceiverConnectionState.connected;
    yield* _connectionCtrl.stream;
  }

  @override
  Stream<ReceiverInfo?> get receiverInfoStream async* {
    yield ReceiverInfo(
      rfmId: Uint8List.fromList(const [1, 2, 3, 4]),
      productModelCode: 0,
      batteryLevel: 88,
      remoteId: 'test-device',
    );
  }

  @override
  Stream<List<ReceiverScanDevice>> get scanResultsStream async* {
    yield const <ReceiverScanDevice>[
      ReceiverScanDevice(
        remoteId: 'test-device',
        name: 'R4P Test',
        rssi: -40,
        connected: true,
      ),
    ];
  }

  @override
  Future<void> exitBleMode() async {
    exitBleModeCalls += 1;
    if (throwOnExit) {
      throw TimeoutException('exit BLE mode response timeout');
    }
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
    _connectionState = ReceiverConnectionState.disconnected;
    _connectionCtrl.add(ReceiverConnectionState.disconnected);
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> dispose() async {
    await _connectionCtrl.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

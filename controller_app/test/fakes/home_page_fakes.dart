import 'package:controller_app/src/provider/bluetooth_domain_provider.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

class FakeHomeBluetoothDomainController extends BluetoothDomainController {
  FakeHomeBluetoothDomainController(super.ref);

  int ensureScanStoppedCalls = 0;
  int disconnectCalls = 0;
  int startListScanSessionCalls = 0;

  @override
  Future<bool> autoReconnectLastDevice({
    Duration timeout = const Duration(seconds: 5),
    bool queueUnavailablePrompt = true,
  }) async => false;

  @override
  Future<BluetoothAvailability> ensureReadyForEntry() async {
    return BluetoothAvailability.ready;
  }

  @override
  Future<void> ensureScanStopped() async {
    ensureScanStoppedCalls += 1;
  }

  @override
  Future<bool> disconnect() async {
    disconnectCalls += 1;
    return true;
  }

  @override
  Future<bool> startListScanSession() async {
    startListScanSessionCalls += 1;
    return true;
  }
}

class FakeHomeReceiverRepository implements ReceiverRepository {
  FakeHomeReceiverRepository({required ReceiverConnectionState connectionState})
    : _connectionState = connectionState;

  final ReceiverConnectionState _connectionState;

  @override
  ReceiverConnectionState get connectionState => _connectionState;

  @override
  ReceiverInfo? get receiverInfo => null;

  @override
  Stream<ReceiverInfo?> get receiverInfoStream => Stream.value(null);

  @override
  Stream<ReceiverConnectionState> get connectionStateStream =>
      Stream.value(_connectionState);

  @override
  Stream<int?> get connectedRssiStream => Stream.value(null);

  @override
  Stream<List<ReceiverScanDevice>> get scanResultsStream =>
      Stream.value(const <ReceiverScanDevice>[]);

  @override
  Stream<AdapterState> get adapterStateStream => Stream.value(AdapterState.on);

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

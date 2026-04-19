import '../client/receiver_ble_client.dart';
import '../models/receiver_models.dart';
import '../session/receiver_session_controller.dart';

class ReceiverRepository {
  factory ReceiverRepository({ReceiverBleClient? client}) {
    final resolvedClient = client ?? ReceiverBleClient();
    return ReceiverRepository._(resolvedClient, client == null);
  }

  ReceiverRepository._(this._client, this._ownsClient)
    : session = ReceiverSessionController(_client);

  final ReceiverBleClient _client;
  final bool _ownsClient;
  final ReceiverSessionController session;

  ReceiverConnectionState get connectionState => session.connectionState;
  List<ReceiverScanDevice> get scanResults => session.scanResults;
  ReceiverInfo? get receiverInfo => session.receiverInfo;
  ReceiverFirmwareInfo? get firmwareInfo => session.firmwareInfo;

  Stream<List<ReceiverScanDevice>> get scanResultsStream =>
      session.scanResultsStream;
  Stream<ReceiverConnectionState> get connectionStateStream =>
      session.connectionStateStream;
  Stream<ReceiverInfo?> get receiverInfoStream => session.receiverInfoStream;
  Stream<ReceiverFirmwareInfo?> get firmwareInfoStream =>
      session.firmwareInfoStream;

  Future<void> startScan() => session.startScan();

  Future<void> stopScan() => session.stopScan();

  Future<ReceiverInfo> connect(String remoteId) async {
    await session.connect(remoteId);
    return session.readReceiverInfo();
  }

  Future<void> disconnect() => session.disconnect();

  Future<ReceiverFailsafeConfig> readFailsafe() => session.readFailsafe();

  Future<ReceiverFailsafeConfig> writeFailsafe(ReceiverFailsafeConfig config) =>
      session.writeFailsafe(config);

  Future<ReceiverFirmwareInfo> readFirmwareInfo() => session.readFirmwareInfo();

  Future<void> updateControlValues(ReceiverControlValues values) =>
      session.updateControlValues(values);

  Future<void> startControlLoop() => session.startControlLoop();

  Future<void> stopControlLoop() => session.stopControlLoop();

  Stream<ReceiverUpgradeProgress> startUpgrade(List<int> firmwareBytes) =>
      session.startUpgrade(firmwareBytes);

  Future<void> dispose() async {
    await session.dispose();
    if (_ownsClient) {
      await _client.dispose();
    }
  }
}

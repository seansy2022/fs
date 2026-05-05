import 'dart:async';
import 'dart:typed_data';

import 'package:rc_ble/rc_ble.dart';

import '../client/receiver_ble_client.dart';
import '../models/receiver_models.dart';

class ReceiverSessionController {
  ReceiverSessionController(this._client) {
    _scanSub = _client.scanResultsStream.listen((results) {
      _scanResults = results;
      _scanCtrl.add(results);
    });
    _connectionSub = _client.connectionStateStream.listen((state) {
      _connectionState = state;
      _connectionCtrl.add(state);
    });
    _infoSub = _client.receiverInfoStream.listen((info) {
      _receiverInfo = info;
      _infoCtrl.add(info);
    });
    _firmwareSub = _client.firmwareInfoStream.listen((info) {
      _firmwareInfo = info;
      _firmwareCtrl.add(info);
    });
    _adapterSub = _client.adapterStateStream.listen((state) {
      _adapterState = state;
      _adapterCtrl.add(state);
    });
  }

  final ReceiverBleClient _client;
  final StreamController<List<ReceiverScanDevice>> _scanCtrl =
      StreamController<List<ReceiverScanDevice>>.broadcast();
  final StreamController<ReceiverConnectionState> _connectionCtrl =
      StreamController<ReceiverConnectionState>.broadcast();
  final StreamController<ReceiverInfo?> _infoCtrl =
      StreamController<ReceiverInfo?>.broadcast();
  final StreamController<ReceiverFirmwareInfo?> _firmwareCtrl =
      StreamController<ReceiverFirmwareInfo?>.broadcast();
  final StreamController<AdapterState> _adapterCtrl =
      StreamController<AdapterState>.broadcast();

  StreamSubscription<List<ReceiverScanDevice>>? _scanSub;
  StreamSubscription<ReceiverConnectionState>? _connectionSub;
  StreamSubscription<ReceiverInfo?>? _infoSub;
  StreamSubscription<ReceiverFirmwareInfo?>? _firmwareSub;
  StreamSubscription<AdapterState>? _adapterSub;

  List<ReceiverScanDevice> _scanResults = const <ReceiverScanDevice>[];
  ReceiverConnectionState _connectionState =
      ReceiverConnectionState.disconnected;
  ReceiverInfo? _receiverInfo;
  ReceiverFirmwareInfo? _firmwareInfo;
  AdapterState _adapterState = AdapterState.unknown;

  List<ReceiverScanDevice> get scanResults => _scanResults;
  ReceiverConnectionState get connectionState => _connectionState;
  ReceiverInfo? get receiverInfo => _receiverInfo;
  ReceiverFirmwareInfo? get firmwareInfo => _firmwareInfo;
  AdapterState get adapterState => _adapterState;

  Stream<List<ReceiverScanDevice>> get scanResultsStream async* {
    yield _scanResults;
    yield* _scanCtrl.stream;
  }

  Stream<ReceiverConnectionState> get connectionStateStream async* {
    yield _connectionState;
    yield* _connectionCtrl.stream;
  }

  Stream<ReceiverInfo?> get receiverInfoStream async* {
    yield _receiverInfo;
    yield* _infoCtrl.stream;
  }

  Stream<ReceiverFirmwareInfo?> get firmwareInfoStream async* {
    yield _firmwareInfo;
    yield* _firmwareCtrl.stream;
  }

  Stream<AdapterState> get adapterStateStream async* {
    yield _adapterState;
    yield* _adapterCtrl.stream;
  }

  Future<bool> turnOnAdapter() => _client.turnOnAdapter();

  Future<void> startScan() => _client.startScan();

  Future<void> stopScan() => _client.stopScan();

  Future<void> connect(String remoteId) => _client.connect(remoteId);

  Future<void> disconnect() => _client.disconnect();

  Future<ReceiverInfo> readReceiverInfo() => _client.readReceiverInfo();

  Future<ReceiverFailsafeConfig> readFailsafe() => _client.readFailsafe();

  Future<ReceiverFailsafeConfig> writeFailsafe(ReceiverFailsafeConfig config) =>
      _client.writeFailsafe(config);

  Future<ReceiverFirmwareInfo> readFirmwareInfo() => _client.readFirmwareInfo();

  Future<void> updateControlValues(ReceiverControlValues values) =>
      _client.updateControlValues(values);

  Future<void> exitBleMode() => _client.exitBleMode();

  Future<void> startControlLoop() => _client.startControlLoop();

  Future<void> stopControlLoop() => _client.stopControlLoop();

  Stream<ReceiverUpgradeProgress> startUpgrade(List<int> firmwareBytes) {
    return _client.startUpgrade(Uint8List.fromList(firmwareBytes));
  }

  Future<void> dispose() async {
    await _scanSub?.cancel();
    await _connectionSub?.cancel();
    await _infoSub?.cancel();
    await _firmwareSub?.cancel();
    await _adapterSub?.cancel();
    await _scanCtrl.close();
    await _connectionCtrl.close();
    await _infoCtrl.close();
    await _adapterCtrl.close();
    await _firmwareCtrl.close();
  }
}

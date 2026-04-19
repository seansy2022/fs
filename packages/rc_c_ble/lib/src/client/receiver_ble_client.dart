import 'dart:async';
import 'dart:typed_data';

import 'package:rc_ble/rc_ble.dart';

import '../models/receiver_models.dart';
import '../protocol/receiver_command.dart';
import '../protocol/receiver_frame.dart';
import '../protocol/receiver_frame_parser.dart';
import '../protocol/receiver_protocol_codec.dart';

class ReceiverBleClient {
  ReceiverBleClient({
    LinkTransport? transport,
    this.requestTimeout = const Duration(milliseconds: 900),
  }) : _transport = transport ?? FlutterBlueTransport() {
    _incomingSub = _transport.incomingBytes.listen(_onBytes);
    _scanSub = _transport.scanResults.listen(_onScanResults);
  }

  final LinkTransport _transport;
  final Duration requestTimeout;
  final ReceiverFrameParser _parser = ReceiverFrameParser();

  final StreamController<List<ReceiverScanDevice>> _scanCtrl =
      StreamController<List<ReceiverScanDevice>>.broadcast();
  final StreamController<ReceiverConnectionState> _connectionCtrl =
      StreamController<ReceiverConnectionState>.broadcast();
  final StreamController<ReceiverInfo?> _infoCtrl =
      StreamController<ReceiverInfo?>.broadcast();
  final StreamController<ReceiverFirmwareInfo?> _firmwareCtrl =
      StreamController<ReceiverFirmwareInfo?>.broadcast();
  final StreamController<ReceiverFrame> _frameCtrl =
      StreamController<ReceiverFrame>.broadcast();

  StreamSubscription<List<int>>? _incomingSub;
  StreamSubscription<List<BluetoothScanDevice>>? _scanSub;
  Timer? _controlLoop;
  Completer<ReceiverFrame>? _pendingResponse;
  bool Function(ReceiverFrame frame)? _pendingMatcher;
  ReceiverConnectionState _connectionState =
      ReceiverConnectionState.disconnected;
  List<ReceiverScanDevice> _scanResults = const <ReceiverScanDevice>[];
  ReceiverInfo? _receiverInfo;
  ReceiverFirmwareInfo? _firmwareInfo;
  ReceiverControlValues _controlValues = const ReceiverControlValues();
  String? _connectedRemoteId;

  ReceiverConnectionState get connectionState => _connectionState;
  List<ReceiverScanDevice> get scanResults => _scanResults;
  ReceiverInfo? get receiverInfo => _receiverInfo;
  ReceiverFirmwareInfo? get firmwareInfo => _firmwareInfo;

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

  Stream<ReceiverFrame> get frameStream => _frameCtrl.stream;

  Future<void> startScan() async {
    _setConnectionState(
      _connectionState == ReceiverConnectionState.connected
          ? ReceiverConnectionState.connected
          : ReceiverConnectionState.scanning,
    );
    await _transport.startScan();
  }

  Future<void> stopScan() async {
    await _transport.stopScan();
    if (_connectionState == ReceiverConnectionState.scanning) {
      _setConnectionState(ReceiverConnectionState.disconnected);
    }
  }

  Future<void> connect(String remoteId) async {
    _setConnectionState(ReceiverConnectionState.connecting);
    await _transport.connect(remoteId);
    _connectedRemoteId = remoteId;
    _scanResults = _scanResults
        .map(
          (device) => device.copyWith(connected: device.remoteId == remoteId),
        )
        .toList(growable: false);
    _scanCtrl.add(_scanResults);
    _setConnectionState(ReceiverConnectionState.connected);
  }

  Future<void> disconnect() async {
    _controlLoop?.cancel();
    _controlLoop = null;
    final remoteId = _connectedRemoteId;
    _connectedRemoteId = null;
    _receiverInfo = null;
    _firmwareInfo = null;
    _infoCtrl.add(null);
    _firmwareCtrl.add(null);
    if (remoteId != null) {
      await _transport.disconnect(remoteId);
    }
    _scanResults = _scanResults
        .map((device) => device.copyWith(connected: false))
        .toList(growable: false);
    _scanCtrl.add(_scanResults);
    _setConnectionState(ReceiverConnectionState.disconnected);
  }

  Future<ReceiverInfo> readReceiverInfo() async {
    final frame = await _sendRequest(
      buildReceiverInfoRequest(),
      matcher: (response) =>
          response.command == ReceiverCommand.receiverInfo.id,
    );
    final info = parseReceiverInfoResponse(frame, remoteId: _connectedRemoteId);
    _receiverInfo = info;
    _infoCtrl.add(info);
    return info;
  }

  Future<ReceiverFailsafeConfig> readFailsafe() async {
    final frame = await _sendRequest(
      buildReadFailsafeRequest(_requireRfmId()),
      matcher: (response) =>
          response.command == ReceiverCommand.readFailsafe.id,
    );
    return parseFailsafeResponse(frame);
  }

  Future<ReceiverFailsafeConfig> writeFailsafe(
    ReceiverFailsafeConfig config,
  ) async {
    final frame = await _sendRequest(
      buildWriteFailsafeRequest(_requireRfmId(), config),
      matcher: (response) =>
          response.command == ReceiverCommand.writeFailsafe.id,
    );
    return parseFailsafeResponse(frame);
  }

  Future<ReceiverFirmwareInfo> readFirmwareInfo() async {
    final frame = await _sendRequest(
      buildFirmwareInfoRequest(_requireRfmId()),
      matcher: (response) =>
          response.command == ReceiverCommand.firmwareInfo.id,
    );
    final info = parseFirmwareInfoResponse(frame);
    _firmwareInfo = info;
    _firmwareCtrl.add(info);
    return info;
  }

  Future<void> updateControlValues(ReceiverControlValues values) async {
    _controlValues = values.sanitize();
  }

  Future<void> startControlLoop() async {
    _requireRfmId();
    _controlLoop?.cancel();
    _controlLoop = Timer.periodic(const Duration(milliseconds: 10), (_) {
      unawaited(_sendControlHeartbeat());
    });
    await _sendControlHeartbeat();
  }

  Future<void> stopControlLoop() async {
    _controlLoop?.cancel();
    _controlLoop = null;
  }

  Stream<ReceiverUpgradeProgress> startUpgrade(Uint8List firmwareBytes) async* {
    if (firmwareBytes.isEmpty) {
      yield const ReceiverUpgradeProgress(
        stage: ReceiverUpgradeStage.failed,
        sentChunks: 0,
        totalChunks: 0,
        message: 'Firmware payload is empty.',
      );
      return;
    }
    final rfmId = _requireRfmId();
    final totalChunks = (firmwareBytes.length / 24).ceil();
    try {
      yield ReceiverUpgradeProgress(
        stage: ReceiverUpgradeStage.enteringBoot,
        sentChunks: 0,
        totalChunks: totalChunks,
      );
      final bootFrame = await _sendRequest(
        buildUpgradeBootRequest(rfmId),
        matcher: (response) =>
            response.command == ReceiverCommand.startUpgradeBoot.id,
      );
      if (parseUpgradeState(bootFrame, stateIndex: 4) != 1) {
        throw StateError('Receiver rejected boot mode.');
      }

      yield ReceiverUpgradeProgress(
        stage: ReceiverUpgradeStage.sendingLength,
        sentChunks: 0,
        totalChunks: totalChunks,
      );
      final lengthFrame = await _sendRequest(
        buildUpgradeLengthRequest(firmwareBytes.length),
        matcher: (response) =>
            response.command == ReceiverCommand.setUpgradeLength.id,
      );
      if (parseUpgradeState(lengthFrame, stateIndex: 4) != 1) {
        throw StateError('Receiver rejected firmware length.');
      }

      for (var index = 0; index < totalChunks; index++) {
        final start = index * 24;
        final end = (start + 24 > firmwareBytes.length)
            ? firmwareBytes.length
            : start + 24;
        final response = await _sendRequest(
          buildUpgradeChunkRequest(index, firmwareBytes.sublist(start, end)),
          matcher: (frame) =>
              frame.command == ReceiverCommand.sendUpgradeChunk.id &&
              frame.data.isNotEmpty &&
              frame.data.first == (index & 0xFF),
        );
        final responseState = parseUpgradeChunkState(response);
        if (parseUpgradeChunkSequence(response) != (index & 0xFF)) {
          throw StateError('Upgrade sequence mismatch.');
        }
        if (responseState != 1 && responseState != 2) {
          throw StateError('Unexpected upgrade state: $responseState');
        }
        yield ReceiverUpgradeProgress(
          stage: responseState == 2
              ? ReceiverUpgradeStage.completed
              : ReceiverUpgradeStage.sendingPayload,
          sentChunks: index + 1,
          totalChunks: totalChunks,
        );
      }
    } catch (error) {
      yield ReceiverUpgradeProgress(
        stage: ReceiverUpgradeStage.failed,
        sentChunks: 0,
        totalChunks: totalChunks,
        message: error.toString(),
      );
    }
  }

  Future<void> dispose() async {
    _controlLoop?.cancel();
    await _incomingSub?.cancel();
    await _scanSub?.cancel();
    await _scanCtrl.close();
    await _connectionCtrl.close();
    await _infoCtrl.close();
    await _firmwareCtrl.close();
    await _frameCtrl.close();
  }

  void _onBytes(List<int> bytes) {
    for (final frame in _parser.addChunk(bytes)) {
      _frameCtrl.add(frame);
      final completer = _pendingResponse;
      final matcher = _pendingMatcher;
      if (completer != null &&
          matcher != null &&
          !completer.isCompleted &&
          matcher(frame)) {
        _pendingResponse = null;
        _pendingMatcher = null;
        completer.complete(frame);
      }
    }
  }

  void _onScanResults(List<BluetoothScanDevice> devices) {
    _scanResults = devices
        .map(
          (device) => ReceiverScanDevice(
            remoteId: device.remoteId,
            name: device.name,
            rssi: device.rssi,
            connected: device.remoteId == _connectedRemoteId,
          ),
        )
        .toList(growable: false);
    _scanCtrl.add(_scanResults);
  }

  Future<ReceiverFrame> _sendRequest(
    ReceiverFrame frame, {
    required bool Function(ReceiverFrame frame) matcher,
  }) async {
    if (_pendingResponse != null) {
      throw StateError('Another receiver request is already pending.');
    }
    final completer = Completer<ReceiverFrame>();
    _pendingResponse = completer;
    _pendingMatcher = matcher;
    try {
      await _transport.send(frame.toBytes());
      return completer.future.timeout(
        requestTimeout,
        onTimeout: () {
          _pendingResponse = null;
          _pendingMatcher = null;
          throw TimeoutException('Timed out waiting for receiver response.');
        },
      );
    } catch (error) {
      _pendingResponse = null;
      _pendingMatcher = null;
      rethrow;
    }
  }

  Future<void> _sendControlHeartbeat() async {
    final rfmId = _requireRfmId();
    await _transport.send(
      buildControlHeartbeatFrame(rfmId, _controlValues).toBytes(),
    );
  }

  Uint8List _requireRfmId() {
    final info = _receiverInfo;
    if (info == null) {
      throw StateError('Receiver info has not been loaded yet.');
    }
    return info.rfmId;
  }

  void _setConnectionState(ReceiverConnectionState state) {
    _connectionState = state;
    _connectionCtrl.add(state);
  }
}

import 'dart:async';
import 'dart:typed_data';

import '../models/receiver_models.dart';
import '../protocol/receiver_command.dart';
import '../protocol/receiver_frame.dart';
import '../protocol/receiver_frame_parser.dart';
import '../protocol/receiver_protocol_codec.dart';
import '../transport/flutter_blue_receiver_transport.dart';
import '../transport/receiver_link_transport.dart';
import '../transport/receiver_logging.dart';

class ReceiverBleClient {
  ReceiverBleClient({
    LinkTransport? transport,
    this.requestTimeout = const Duration(milliseconds: 900),
  }) : _transport = transport ?? FlutterBlueReceiverTransport() {
    _incomingSub = _transport.incomingBytes.listen(_onBytes);
    _scanSub = _transport.scanResults.listen(
      _onScanResults,
      onError: _onScanError,
    );
    _adapterSub = _transport.adapterState.listen((state) {
      _adapterState = state;
      _adapterCtrl.add(state);
    });
  }

  final LinkTransport _transport;
  final Duration requestTimeout;
  final ReceiverFrameParser _parser = ReceiverFrameParser();
  static const Duration _scanRestartCooldown = Duration(milliseconds: 700);

  StreamSubscription<AdapterState>? _adapterSub;

  final StreamController<List<ReceiverScanDevice>> _scanCtrl =
      StreamController<List<ReceiverScanDevice>>.broadcast();
  final StreamController<ReceiverConnectionState> _connectionCtrl =
      StreamController<ReceiverConnectionState>.broadcast();
  final StreamController<ReceiverInfo?> _infoCtrl =
      StreamController<ReceiverInfo?>.broadcast();
  final StreamController<int?> _connectedRssiCtrl =
      StreamController<int?>.broadcast();
  final StreamController<ReceiverFirmwareInfo?> _firmwareCtrl =
      StreamController<ReceiverFirmwareInfo?>.broadcast();
  final StreamController<ReceiverFrame> _frameCtrl =
      StreamController<ReceiverFrame>.broadcast();
  final StreamController<AdapterState> _adapterCtrl =
      StreamController<AdapterState>.broadcast();

  StreamSubscription<List<int>>? _incomingSub;
  StreamSubscription<List<BluetoothScanDevice>>? _scanSub;
  Timer? _controlLoop;
  Timer? _rssiLoop;
  Completer<ReceiverFrame>? _pendingResponse;
  bool Function(ReceiverFrame frame)? _pendingMatcher;
  ReceiverConnectionState _connectionState =
      ReceiverConnectionState.disconnected;
  List<ReceiverScanDevice> _scanResults = const <ReceiverScanDevice>[];
  ReceiverInfo? _receiverInfo;
  int? _connectedRssi;
  ReceiverFirmwareInfo? _firmwareInfo;
  ReceiverControlValues _controlValues = const ReceiverControlValues();
  String? _connectedRemoteId;
  AdapterState _adapterState = AdapterState.unknown;
  Future<void> _scanQueue = Future<void>.value();
  bool _isScanning = false;
  bool _rssiPollingEnabled = false;
  bool _rssiReadInFlight = false;
  DateTime? _lastScanStopAt;

  ReceiverConnectionState get connectionState => _connectionState;
  List<ReceiverScanDevice> get scanResults => _scanResults;
  ReceiverInfo? get receiverInfo => _receiverInfo;
  int? get connectedRssi => _connectedRssi;
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

  Stream<int?> get connectedRssiStream async* {
    yield _connectedRssi;
    yield* _connectedRssiCtrl.stream;
  }

  Stream<ReceiverFirmwareInfo?> get firmwareInfoStream async* {
    yield _firmwareInfo;
    yield* _firmwareCtrl.stream;
  }

  Stream<AdapterState> get adapterStateStream async* {
    yield _adapterState;
    yield* _adapterCtrl.stream;
  }

  Future<bool> turnOnAdapter() => _transport.turnOnAdapter();

  Stream<ReceiverFrame> get frameStream => _frameCtrl.stream;

  Future<void> startScan() {
    return _enqueueScanOperation(() async {
      if (_isScanning) {
        if (_connectionState != ReceiverConnectionState.connected) {
          _setConnectionState(ReceiverConnectionState.scanning);
        }
        return;
      }
      _setConnectionState(
        _connectionState == ReceiverConnectionState.connected
            ? ReceiverConnectionState.connected
            : ReceiverConnectionState.scanning,
      );
      await _waitForScanCooldown();
      try {
        await _transport.startScan();
        _isScanning = true;
      } catch (error) {
        _isScanning = false;
        _lastScanStopAt = DateTime.now();
        if (_connectionState == ReceiverConnectionState.scanning) {
          _setConnectionState(ReceiverConnectionState.disconnected);
        }
        rethrow;
      }
    });
  }

  Future<void> stopScan() {
    return _enqueueScanOperation(() async {
      if (!_isScanning) {
        if (_connectionState == ReceiverConnectionState.scanning) {
          _setConnectionState(ReceiverConnectionState.disconnected);
        }
        return;
      }
      try {
        await _transport.stopScan();
      } finally {
        _isScanning = false;
        _lastScanStopAt = DateTime.now();
        if (_connectionState == ReceiverConnectionState.scanning) {
          _setConnectionState(ReceiverConnectionState.disconnected);
        }
      }
    });
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
    _seedConnectedRssiFromScan(remoteId);
    _startConnectedRssiPolling();
  }

  Future<void> disconnect() async {
    _controlLoop?.cancel();
    _controlLoop = null;
    _stopConnectedRssiPolling();
    final remoteId = _connectedRemoteId;
    _connectedRemoteId = null;
    _receiverInfo = null;
    _connectedRssi = null;
    _firmwareInfo = null;
    _infoCtrl.add(null);
    _connectedRssiCtrl.add(null);
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

  Future<void> exitBleMode() async {
    _controlLoop?.cancel();
    _controlLoop = null;
    await _sendRequest(
      buildExitBleModeRequest(_requireRfmId()),
      matcher: (response) => response.command == ReceiverCommand.exitBleMode.id,
    );
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
    _stopConnectedRssiPolling();
    await stopScan();
    await _incomingSub?.cancel();
    await _scanSub?.cancel();
    await _adapterSub?.cancel();
    await _scanCtrl.close();
    await _connectionCtrl.close();
    await _infoCtrl.close();
    await _connectedRssiCtrl.close();
    await _adapterCtrl.close();
    await _firmwareCtrl.close();
    await _frameCtrl.close();
  }

  void _onBytes(List<int> bytes) {
    for (final frame in _parser.addChunk(bytes)) {
      ReceiverLogging.link(
        'rx frame cmd=${_describeCommand(frame.command)} len=${frame.length} data=${ReceiverLogging.hexBytes(frame.data)}',
        scope: 'ReceiverBleClient',
      );
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
    final deduped = <String, ReceiverScanDevice>{};
    for (final device in devices) {
      final next = ReceiverScanDevice(
        remoteId: device.remoteId,
        name: device.name,
        rssi: device.rssi,
        connected: device.remoteId == _connectedRemoteId,
      );
      final current = deduped[device.remoteId];
      if (current == null) {
        deduped[device.remoteId] = next;
        continue;
      }
      final preferred = _preferScanDevice(current, next);
      deduped[device.remoteId] = preferred;
    }
    _scanResults = deduped.values.toList(growable: false);
    _scanCtrl.add(_scanResults);
  }

  void _onScanError(Object error, StackTrace stackTrace) {
    _isScanning = false;
    _lastScanStopAt = DateTime.now();
    if (_connectionState == ReceiverConnectionState.scanning) {
      _setConnectionState(ReceiverConnectionState.disconnected);
    }
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
      ReceiverLogging.link(
        'tx frame cmd=${_describeCommand(frame.command)} len=${frame.length} data=${ReceiverLogging.hexBytes(frame.data)}',
        scope: 'ReceiverBleClient',
      );
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
    final frame = buildControlHeartbeatFrame(rfmId, _controlValues);
    ReceiverLogging.link(
      'tx frame cmd=${_describeCommand(frame.command)} len=${frame.length} data=${ReceiverLogging.hexBytes(frame.data)}',
      scope: 'ReceiverBleClient',
    );
    await _transport.send(frame.toBytes());
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

  void _seedConnectedRssiFromScan(String remoteId) {
    final scanDevice = _scanResults
        .where((device) => device.remoteId == remoteId)
        .cast<ReceiverScanDevice?>()
        .firstOrNull;
    if (scanDevice == null) {
      return;
    }
    _connectedRssi = scanDevice.rssi;
    _connectedRssiCtrl.add(scanDevice.rssi);
  }

  void _startConnectedRssiPolling() {
    _rssiLoop?.cancel();
    _rssiPollingEnabled = true;
    unawaited(_readConnectedRssi());
    _rssiLoop = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_readConnectedRssi());
    });
  }

  void _stopConnectedRssiPolling() {
    _rssiPollingEnabled = false;
    _rssiLoop?.cancel();
    _rssiLoop = null;
    _rssiReadInFlight = false;
  }

  Future<void> _readConnectedRssi() async {
    if (_rssiReadInFlight) {
      return;
    }
    final remoteId = _connectedRemoteId;
    if (remoteId == null ||
        _connectionState != ReceiverConnectionState.connected) {
      return;
    }
    _rssiReadInFlight = true;
    try {
      final rssi = await _transport.readRssi(remoteId);
      if (!_rssiPollingEnabled ||
          _connectedRemoteId != remoteId ||
          _connectionState != ReceiverConnectionState.connected) {
        return;
      }
      _connectedRssi = rssi;
      _connectedRssiCtrl.add(rssi);
    } catch (_) {
      // RSSI reads are best-effort; connection state and control traffic own
      // disconnect handling.
    } finally {
      _rssiReadInFlight = false;
    }
  }

  ReceiverScanDevice _preferScanDevice(
    ReceiverScanDevice current,
    ReceiverScanDevice next,
  ) {
    if (next.connected && !current.connected) {
      return next;
    }
    if (next.name.trim().isNotEmpty && current.name.trim().isEmpty) {
      return next;
    }
    if (next.rssi > current.rssi) {
      return next;
    }
    return current;
  }

  Future<void> _enqueueScanOperation(Future<void> Function() task) {
    final completer = Completer<void>();
    _scanQueue = _scanQueue.then((_) async {
      try {
        await task();
        if (!completer.isCompleted) {
          completer.complete();
        }
      } catch (error, stack) {
        if (!completer.isCompleted) {
          completer.completeError(error, stack);
        }
      }
    });
    return completer.future;
  }

  Future<void> _waitForScanCooldown() async {
    final lastScanStopAt = _lastScanStopAt;
    if (lastScanStopAt == null) {
      return;
    }
    final elapsed = DateTime.now().difference(lastScanStopAt);
    final remaining = _scanRestartCooldown - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  String _describeCommand(int commandId) {
    final command = ReceiverCommand.fromId(commandId);
    final hex =
        '0x${commandId.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    if (command == null) {
      return hex;
    }
    return '${command.name}($hex)';
  }
}

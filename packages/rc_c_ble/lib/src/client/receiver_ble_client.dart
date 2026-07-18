import 'dart:async';
import 'dart:typed_data';

import 'receiver_control_buffer.dart';
import '../models/receiver_models.dart';
import '../protocol/receiver_command.dart';
import '../protocol/receiver_frame.dart';
import '../protocol/receiver_frame_parser.dart';
import '../protocol/receiver_protocol_codec.dart';
import '../transport/flutter_blue_receiver_transport.dart';
import '../transport/receiver_link_transport.dart';
import '../transport/receiver_logging.dart';

class ReceiverBleClient {
  static final Uint8List _zeroRfmId = Uint8List(4);

  ReceiverBleClient({
    LinkTransport? transport,
    this.requestTimeout = const Duration(milliseconds: 900),
    this.bootRequestRetryDelay = _defaultBootRequestRetryDelay,
  }) : _transport = transport ?? FlutterBlueReceiverTransport() {
    _incomingSub = _transport.incomingBytes.listen(_onBytes);
    _scanSub = _transport.scanResults.listen(
      _onScanResults,
      onError: _onScanError,
    );
    _transportConnectionSub = _transport.connectionEvents.listen(
      _onTransportConnectionEvent,
    );
    _adapterSub = _transport.adapterState.listen(_onAdapterStateChanged);
  }

  final LinkTransport _transport;
  final Duration requestTimeout;
  final Duration bootRequestRetryDelay;
  final ReceiverFrameParser _parser = ReceiverFrameParser();
  static const Duration _scanRestartCooldown = Duration(milliseconds: 700);
  static const Duration _defaultBootRequestRetryDelay = Duration(
    milliseconds: 100,
  );
  static const Duration _bootDisconnectTimeout = Duration(seconds: 5);
  static const Duration _bootReconnectTimeout = Duration(seconds: 20);
  static const Duration _bootReconnectRetryDelay = Duration(milliseconds: 700);

  StreamSubscription<AdapterState>? _adapterSub;
  StreamSubscription<ReceiverLinkConnectionEvent>? _transportConnectionSub;

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
  Timer? _receiverInfoLoop;
  Completer<ReceiverFrame>? _pendingResponse;
  bool Function(ReceiverFrame frame)? _pendingMatcher;
  ReceiverConnectionState _connectionState =
      ReceiverConnectionState.disconnected;
  List<ReceiverScanDevice> _scanResults = const <ReceiverScanDevice>[];
  ReceiverInfo? _receiverInfo;
  int? _connectedRssi;
  ReceiverFirmwareInfo? _firmwareInfo;
  final ReceiverControlBuffer _controlBuffer = ReceiverControlBuffer();
  String? _connectedRemoteId;
  AdapterState _adapterState = AdapterState.unknown;
  Future<void> _scanQueue = Future<void>.value();
  bool _isScanning = false;
  bool _rssiPollingEnabled = false;
  bool _rssiReadInFlight = false;
  bool _receiverInfoPollingEnabled = false;
  bool _receiverInfoReadInFlight = false;
  DateTime? _lastScanStopAt;
  DateTime? _lastControlLogAt;
  Completer<void>? _scanAndConnectCancelCompleter;

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

  Future<void> startScan({List<String>? withRemoteIds, Duration? timeout}) {
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
        await _transport.startScan(
          withRemoteIds: withRemoteIds,
          timeout: timeout,
        );
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
    if (_connectedRemoteId == remoteId &&
        _connectionState == ReceiverConnectionState.connected) {
      return;
    }
    if (_connectedRemoteId != null && _connectedRemoteId != remoteId) {
      await disconnect();
    }
    _setConnectionState(ReceiverConnectionState.connecting);
    try {
      await _transport.connect(remoteId);
      _isScanning = false;
      _lastScanStopAt = DateTime.now();
      _controlBuffer.clear();
      _connectedRemoteId = remoteId;
      _markScanDeviceConnection(remoteId: remoteId);
      _setConnectionState(ReceiverConnectionState.connected);
      _seedConnectedRssiFromScan(remoteId);
      _startConnectedRssiPolling();
      _startReceiverInfoPolling();
    } catch (error) {
      try {
        await _transport.disconnect(remoteId);
      } catch (_) {
        // Cleanup is best-effort; callers still need the original error.
      }
      _resetConnectionState(remoteId: remoteId);
      rethrow;
    }
  }

  Future<void> scanAndConnectByBlueId(
    String blueId, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_connectedRemoteId == blueId &&
        _connectionState == ReceiverConnectionState.connected) {
      return;
    }
    if (_connectedRemoteId != null && _connectedRemoteId != blueId) {
      await disconnect();
    }
    _scanAndConnectCancelCompleter = Completer<void>();
    final result = await _scanForRemoteId(blueId, timeout: timeout);
    _scanAndConnectCancelCompleter = null;
    if (result == _ScanForRemoteIdResult.cancelled) {
      throw const ReceiverScanConnectCancelledException();
    }
    if (result != _ScanForRemoteIdResult.found) {
      throw TimeoutException('Unable to find bluetooth device: $blueId');
    }
    await connect(blueId);
  }

  Future<void> cancelPendingScanAndConnect() async {
    final completer = _scanAndConnectCancelCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    await stopScan();
  }

  Future<void> disconnect() async {
    final remoteId = _connectedRemoteId;
    try {
      if (remoteId != null) {
        await _transport.disconnect(remoteId);
      }
    } finally {
      _resetConnectionState(remoteId: remoteId);
    }
  }

  Future<ReceiverInfo> readReceiverInfo({bool restartPolling = true}) async {
    final frame = await _sendRequest(
      buildReceiverInfoRequest(),
      matcher: (response) =>
          response.command == ReceiverCommand.receiverInfo.id,
    );
    final info = parseReceiverInfoResponse(frame, remoteId: _connectedRemoteId);
    _receiverInfo = info;
    _infoCtrl.add(info);
    if (restartPolling) {
      _startReceiverInfoPolling();
    }
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
    final rfmId = _requireRfmId();
    final request = buildWriteFailsafeRequest(rfmId, config);
    final frame = await _sendRequest(
      request,
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
    _controlBuffer.updateBase(values);
    if (ReceiverLogging.controlEnabled) {
      ReceiverLogging.phone(
        '[control][base] ch1=${values.throttle} ch2=${values.steering} '
        'ch3=${values.auxChannels[0]} ch4=${values.auxChannels[1]}',
        scope: 'ReceiverBleClient',
      );
    }
  }

  Future<void> queueAuxChannelPulse(int auxChannelIndex, int value) async {
    _controlBuffer.queueAuxPulse(auxChannelIndex, value);
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
    _controlLoop?.cancel();
    _controlLoop = Timer.periodic(const Duration(milliseconds: 30), (_) {
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
    _stopReceiverInfoPolling();
    final remoteId = _connectedRemoteId;
    if (remoteId == null) {
      yield const ReceiverUpgradeProgress(
        stage: ReceiverUpgradeStage.failed,
        sentChunks: 0,
        totalChunks: 0,
        message: 'Receiver is not connected.',
      );
      return;
    }
    final rfmId = _requireRfmId();
    final totalChunks = (firmwareBytes.length / 23).ceil();
    try {
      ReceiverLogging.phone(
        '[upgrade] start rfmId=${ReceiverLogging.hexBytes(rfmId)} '
        'bytes=${firmwareBytes.length} chunks=$totalChunks chunkSize=23',
        scope: 'ReceiverBleClient',
      );
      yield ReceiverUpgradeProgress(
        stage: ReceiverUpgradeStage.enteringBoot,
        sentChunks: 0,
        totalChunks: totalChunks,
      );
      ReceiverLogging.phone(
        '[upgrade][0x12] request boot mode',
        scope: 'ReceiverBleClient',
      );
      await _waitForBootReady(rfmId);

      yield ReceiverUpgradeProgress(
        stage: ReceiverUpgradeStage.waitingBootReconnect,
        sentChunks: 0,
        totalChunks: totalChunks,
      );
      await _reconnectForBootUpgrade(remoteId);

      yield ReceiverUpgradeProgress(
        stage: ReceiverUpgradeStage.sendingLength,
        sentChunks: 0,
        totalChunks: totalChunks,
      );
      ReceiverLogging.phone(
        '[upgrade][0x13] send firmware length=${firmwareBytes.length}',
        scope: 'ReceiverBleClient',
      );
      final lengthFrame = await _sendRequest(
        buildUpgradeLengthRequest(firmwareBytes.length),
        matcher: (response) =>
            response.command == ReceiverCommand.setUpgradeLength.id,
      );
      final lengthState = parseUpgradeState(lengthFrame, stateIndex: 4);
      ReceiverLogging.device(
        '[upgrade][0x13] response state=$lengthState '
        'data=${ReceiverLogging.hexBytes(lengthFrame.data)}',
        scope: 'ReceiverBleClient',
      );
      if (lengthState != 1) {
        ReceiverLogging.device(
          '[upgrade][0x13] ignore state=$lengthState and continue',
          scope: 'ReceiverBleClient',
        );
      }

      for (var index = 0; index < totalChunks; index++) {
        final start = index * 23;
        final end = (start + 23 > firmwareBytes.length)
            ? firmwareBytes.length
            : start + 23;
        final chunk = firmwareBytes.sublist(start, end);
        ReceiverLogging.phone(
          '[upgrade][0x14] send seq=$index/${totalChunks - 1} '
          'offset=$start size=${chunk.length}',
          scope: 'ReceiverBleClient',
        );
        final response = await _sendRequest(
          buildUpgradeChunkRequest(index, chunk),
          matcher: (frame) =>
              frame.command == ReceiverCommand.sendUpgradeChunk.id &&
              frame.data.length == 3 &&
              parseUpgradeChunkSequence(frame) == index,
        );
        final responseSeq = parseUpgradeChunkSequence(response);
        final responseState = parseUpgradeChunkState(response);
        ReceiverLogging.device(
          '[upgrade][0x14] ack seq=$responseSeq state=$responseState '
          'data=${ReceiverLogging.hexBytes(response.data)}',
          scope: 'ReceiverBleClient',
        );
        if (responseSeq != index) {
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
      ReceiverLogging.device(
        '[upgrade] completed totalChunks=$totalChunks bytes=${firmwareBytes.length}',
        scope: 'ReceiverBleClient',
      );
    } catch (error) {
      ReceiverLogging.device(
        '[upgrade] failed error=$error',
        scope: 'ReceiverBleClient',
      );
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
    _stopReceiverInfoPolling();
    await stopScan();
    await _incomingSub?.cancel();
    await _scanSub?.cancel();
    await _transportConnectionSub?.cancel();
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
      if (ReceiverLogging.controlEnabled &&
          frame.command == ReceiverCommand.controlHeartbeat.id) {
        final frameBytes = frame.toBytes();
        ReceiverLogging.device(
          '[control][rx][0x02] bytes(${frameBytes.length})='
          '${ReceiverLogging.hexBytes(frameBytes)}',
          scope: 'ReceiverBleClient',
        );
      }
      _updateReceiverInfoFromHeartbeat(frame);
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
        connected: device.connected || device.remoteId == _connectedRemoteId,
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
    final isUpgradeCommand =
        frame.command >= ReceiverCommand.firmwareInfo.id &&
        frame.command <= ReceiverCommand.sendUpgradeChunk.id;
    try {
      final requestBytes = frame.toBytes();
      if (isUpgradeCommand) {
        ReceiverLogging.upgradePhone(
          '[upgrade][tx] cmd=0x${frame.command.toRadixString(16).padLeft(2, '0').toUpperCase()} '
          'bytes(${requestBytes.length})=${ReceiverLogging.hexBytes(requestBytes)}',
          scope: 'ReceiverBleClient',
        );
      }
      await _transport.send(requestBytes);
      final response = await completer.future.timeout(
        requestTimeout,
        onTimeout: () {
          _pendingResponse = null;
          _pendingMatcher = null;
          throw TimeoutException('Timed out waiting for receiver response.');
        },
      );
      if (isUpgradeCommand) {
        final responseBytes = response.toBytes();
        ReceiverLogging.upgradeDevice(
          '[upgrade][rx] cmd=0x${response.command.toRadixString(16).padLeft(2, '0').toUpperCase()} '
          'bytes(${responseBytes.length})=${ReceiverLogging.hexBytes(responseBytes)}',
          scope: 'ReceiverBleClient',
        );
      }
      return response;
    } catch (error) {
      if (isUpgradeCommand) {
        ReceiverLogging.upgradeDevice(
          '[upgrade][error] cmd=0x${frame.command.toRadixString(16).padLeft(2, '0').toUpperCase()} '
          '$error',
          scope: 'ReceiverBleClient',
        );
      }
      _pendingResponse = null;
      _pendingMatcher = null;
      rethrow;
    }
  }

  Future<void> _sendControlHeartbeat() async {
    final rfmId = _receiverInfo?.rfmId ?? _zeroRfmId;
    final values = _controlBuffer.consumeNextValues();
    final now = DateTime.now();
    if (ReceiverLogging.controlEnabled &&
        (_lastControlLogAt == null ||
            now.difference(_lastControlLogAt!) >= const Duration(seconds: 1))) {
      _lastControlLogAt = now;
      ReceiverLogging.phone(
        '[control][heartbeat] ch1=${values.throttle} ch2=${values.steering} '
        'ch3=${values.auxChannels[0]} ch4=${values.auxChannels[1]}',
        scope: 'ReceiverBleClient',
      );
    }
    final frame = buildControlHeartbeatFrame(rfmId, values);
    final frameBytes = frame.toBytes();
    if (ReceiverLogging.controlEnabled) {
      ReceiverLogging.phone(
        '[control][tx][0x02] bytes(${frameBytes.length})='
        '${ReceiverLogging.hexBytes(frameBytes)}',
        scope: 'ReceiverBleClient',
      );
    }
    await _transport.send(frameBytes, preferWithoutResponse: true);
  }

  Future<void> _reconnectForBootUpgrade(String remoteId) async {
    ReceiverLogging.phone(
      '[upgrade] wait boot reconnect remoteId=$remoteId',
      scope: 'ReceiverBleClient',
    );
    _stopConnectedRssiPolling();
    _stopReceiverInfoPolling();

    final disconnected = await _waitForDisconnected(
      timeout: _bootDisconnectTimeout,
    );
    if (!disconnected) {
      ReceiverLogging.device(
        '[upgrade] boot disconnect not observed, rebinding BLE link',
        scope: 'ReceiverBleClient',
      );
    }

    await _connectForUpgrade(remoteId, timeout: _bootReconnectTimeout);
    ReceiverLogging.device(
      '[upgrade] boot BLE reconnected',
      scope: 'ReceiverBleClient',
    );
  }

  /// 持续发送 0x12，直到接收器回传 data[4] = 3 表示 Boot 已就绪。
  Future<void> _waitForBootReady(Uint8List rfmId) async {
    var attempt = 0;

    while (true) {
      attempt++;
      try {
        final bootFrame = await _sendRequest(
          buildUpgradeBootRequest(rfmId),
          matcher: (response) =>
              response.command == ReceiverCommand.startUpgradeBoot.id,
        );
        final bootState = parseUpgradeState(bootFrame, stateIndex: 4);
        ReceiverLogging.device(
          '[upgrade][0x12] attempt=$attempt state=$bootState '
          'data=${ReceiverLogging.hexBytes(bootFrame.data)}',
          scope: 'ReceiverBleClient',
        );
        if (bootState == 3) {
          return;
        }
        if (bootState < 0 || bootState > 2) {
          throw StateError('Unexpected boot upgrade state: $bootState');
        }
      } on TimeoutException {
        ReceiverLogging.device(
          '[upgrade][0x12] attempt=$attempt response timeout, retrying',
          scope: 'ReceiverBleClient',
        );
      }

      await Future<void>.delayed(bootRequestRetryDelay);
    }
  }

  Future<bool> _waitForDisconnected({required Duration timeout}) async {
    if (_connectionState == ReceiverConnectionState.disconnected) {
      return true;
    }
    try {
      await connectionStateStream
          .firstWhere((state) => state == ReceiverConnectionState.disconnected)
          .timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> _connectForUpgrade(
    String remoteId, {
    required Duration timeout,
  }) async {
    final deadline = DateTime.now().add(timeout);
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      _setConnectionState(ReceiverConnectionState.connecting);
      try {
        await _transport.connect(remoteId);
        _isScanning = false;
        _lastScanStopAt = DateTime.now();
        _connectedRemoteId = remoteId;
        _markScanDeviceConnection(remoteId: remoteId);
        _setConnectionState(ReceiverConnectionState.connected);
        return;
      } catch (error) {
        lastError = error;
        try {
          await _transport.disconnect(remoteId);
        } catch (_) {
          // Best-effort cleanup before the next reconnect attempt.
        }
        _resetConnectionState(remoteId: remoteId);
        final remaining = deadline.difference(DateTime.now());
        if (remaining <= Duration.zero) {
          break;
        }
        final delay = remaining < _bootReconnectRetryDelay
            ? remaining
            : _bootReconnectRetryDelay;
        await Future<void>.delayed(delay);
      }
    }
    throw TimeoutException(
      'Timed out waiting for receiver boot reconnect. Last error: $lastError',
      timeout,
    );
  }

  Uint8List _requireRfmId() {
    final info = _receiverInfo;
    if (info == null) {
      throw StateError('Receiver info has not been loaded yet.');
    }
    return info.rfmId;
  }

  void _updateReceiverInfoFromHeartbeat(ReceiverFrame frame) {
    if (frame.command != ReceiverCommand.controlHeartbeat.id ||
        frame.data.length < 4) {
      return;
    }
    final nextInfo = parseHeartbeatReceiverInfo(
      frame,
      remoteId: _connectedRemoteId,
      previous: _receiverInfo,
    );
    final previous = _receiverInfo;
    if (previous != null &&
        previous.rfmIdHex == nextInfo.rfmIdHex &&
        previous.remoteId == nextInfo.remoteId &&
        previous.productModelCode == nextInfo.productModelCode &&
        previous.batteryLevel == nextInfo.batteryLevel) {
      return;
    }
    _receiverInfo = nextInfo;
    _infoCtrl.add(nextInfo);
  }

  void _setConnectionState(ReceiverConnectionState state) {
    _connectionState = state;
    _connectionCtrl.add(state);
  }

  void _onAdapterStateChanged(AdapterState state) {
    _adapterState = state;
    _adapterCtrl.add(state);
    if (state != AdapterState.off && state != AdapterState.turningOff) {
      return;
    }
    _isScanning = false;
    final activeRemoteId = _connectedRemoteId;
    if (activeRemoteId != null ||
        _connectionState == ReceiverConnectionState.scanning) {
      _resetConnectionState(remoteId: activeRemoteId);
    }
  }

  void _onTransportConnectionEvent(ReceiverLinkConnectionEvent event) {
    if (event.state == ReceiverLinkConnectionState.connected) {
      return;
    }
    _markScanDeviceConnection(remoteId: event.remoteId);
    if (_connectedRemoteId != event.remoteId) {
      return;
    }
    _resetConnectionState(remoteId: event.remoteId);
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

  void _markScanDeviceConnection({String? remoteId}) {
    _scanResults = _scanResults
        .map(
          (device) => device.copyWith(
            connected: remoteId != null && device.remoteId == remoteId,
          ),
        )
        .toList(growable: false);
    _scanCtrl.add(_scanResults);
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

  void _startReceiverInfoPolling() {
    _receiverInfoLoop?.cancel();
    _receiverInfoPollingEnabled = true;
    _receiverInfoLoop = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_pollReceiverInfo());
    });
  }

  void _stopReceiverInfoPolling() {
    _receiverInfoPollingEnabled = false;
    _receiverInfoLoop?.cancel();
    _receiverInfoLoop = null;
    _receiverInfoReadInFlight = false;
  }

  Future<void> _pollReceiverInfo() async {
    if (!_receiverInfoPollingEnabled ||
        _receiverInfoReadInFlight ||
        _pendingResponse != null ||
        _connectedRemoteId == null ||
        _connectionState != ReceiverConnectionState.connected) {
      return;
    }
    _receiverInfoReadInFlight = true;
    try {
      await readReceiverInfo(restartPolling: false);
    } catch (_) {
      // Polling is best-effort; explicit requests still surface errors.
    } finally {
      _receiverInfoReadInFlight = false;
    }
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

  void _resetConnectionState({String? remoteId}) {
    _controlLoop?.cancel();
    _controlLoop = null;
    _stopConnectedRssiPolling();
    _stopReceiverInfoPolling();
    _controlBuffer.clear();
    _connectedRemoteId = null;
    _receiverInfo = null;
    _connectedRssi = null;
    _firmwareInfo = null;
    _infoCtrl.add(null);
    _connectedRssiCtrl.add(null);
    _firmwareCtrl.add(null);
    _markScanDeviceConnection();
    final activeRemoteId = remoteId ?? _connectedRemoteId;
    if (activeRemoteId != null &&
        _connectionState != ReceiverConnectionState.scanning) {
      _lastScanStopAt ??= DateTime.now();
    }
    _setConnectionState(ReceiverConnectionState.disconnected);
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

  Future<_ScanForRemoteIdResult> _scanForRemoteId(
    String remoteId, {
    required Duration timeout,
  }) async {
    if (_scanResults.any((device) => device.remoteId == remoteId)) {
      return _ScanForRemoteIdResult.found;
    }
    final completer = Completer<_ScanForRemoteIdResult>();
    late final StreamSubscription<List<ReceiverScanDevice>> subscription;
    Timer? timer;

    void complete(_ScanForRemoteIdResult result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    subscription = scanResultsStream.listen((devices) {
      if (devices.any((device) => device.remoteId == remoteId)) {
        complete(_ScanForRemoteIdResult.found);
      }
    });
    timer = Timer(timeout, () => complete(_ScanForRemoteIdResult.timeout));
    _scanAndConnectCancelCompleter?.future.then((_) {
      complete(_ScanForRemoteIdResult.cancelled);
    });

    try {
      await startScan(withRemoteIds: <String>[remoteId], timeout: timeout);
      if (_scanResults.any((device) => device.remoteId == remoteId)) {
        complete(_ScanForRemoteIdResult.found);
      }
      return await completer.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
      await stopScan();
    }
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
}

enum _ScanForRemoteIdResult { found, timeout, cancelled }

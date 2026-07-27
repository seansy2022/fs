import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_gatt_support.dart';
import 'receiver_link_transport.dart';
import 'receiver_logging.dart';

/// 判断与发送帧完全一致的通知是否仍应作为接收机协议应答处理。
bool shouldUseReceiverEchoAsProtocolReply(int? command) {
  return command == 0x07 || command == 0x08 || command == 0x13;
}

class FlutterBlueReceiverTransport implements ReceiverBluetoothTransport {
  FlutterBlueReceiverTransport({LogLevel logLevel = LogLevel.none}) {
    unawaited(FlutterBluePlus.setLogLevel(logLevel));
  }

  final Map<String, BluetoothDevice> _known = <String, BluetoothDevice>{};
  // 通知帧必须同步交给请求匹配器，避免末包成功应答与超时竞争。
  final StreamController<List<int>> _incomingCtrl =
      StreamController<List<int>>.broadcast(sync: true);
  StreamSubscription<List<int>>? _notifySub;
  BluetoothDevice? _activeDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  List<int>? _lastSentBytes;
  AdapterState _adapterState = AdapterState.unknown;
  Future<void> _scanQueue = Future<void>.value();
  bool _isScanning = false;
  DateTime? _lastScanStopAt;

  static const Duration _scanRestartCooldown = Duration(milliseconds: 700);

  @override
  ReceiverLinkType get type => ReceiverLinkType.ble;

  @override
  AdapterState get currentAdapterState => _adapterState;

  @override
  Stream<AdapterState> get adapterState {
    return FlutterBluePlus.adapterState.map(_mapAdapterState);
  }

  @override
  Stream<ReceiverLinkConnectionEvent> get connectionEvents {
    return FlutterBluePlus.events.onConnectionStateChanged.map(
      _mapConnectionEvent,
    );
  }

  @override
  Stream<List<ReceiverBluetoothScanDevice>> get scanResults {
    return FlutterBluePlus.scanResults
        .handleError(_handleScanStreamError)
        .map(_mapScanResults);
  }

  @override
  Stream<List<int>> get incomingBytes => _incomingCtrl.stream;

  @override
  Future<void> startScan({List<String>? withRemoteIds, Duration? timeout}) {
    return _enqueueScanOperation(() async {
      if (_isScanning || FlutterBluePlus.isScanningNow) {
        ReceiverLogging.link(
          'startScan skipped: already scanning',
          scope: 'FlutterBlueReceiverTransport',
        );
        _isScanning = true;
        return;
      }
      await _stopNativeScanIfNeeded();
      await _waitForScanCooldown();
      ReceiverLogging.link('startScan', scope: 'FlutterBlueReceiverTransport');
      try {
        await FlutterBluePlus.startScan(
          withRemoteIds: withRemoteIds ?? const <String>[],
          timeout: timeout,
        );
        _isScanning = true;
      } catch (error) {
        _isScanning = false;
        _lastScanStopAt = DateTime.now();
        rethrow;
      }
    });
  }

  @override
  Future<void> stopScan() {
    return _enqueueScanOperation(() async {
      if (!_isScanning && !FlutterBluePlus.isScanningNow) {
        ReceiverLogging.link(
          'stopScan skipped: not scanning',
          scope: 'FlutterBlueReceiverTransport',
        );
        return;
      }
      ReceiverLogging.link('stopScan', scope: 'FlutterBlueReceiverTransport');
      try {
        await FlutterBluePlus.stopScan();
      } finally {
        _isScanning = false;
        _lastScanStopAt = DateTime.now();
      }
    });
  }

  @override
  Future<void> connect(String remoteId) async {
    ReceiverLogging.link(
      'connect remoteId=$remoteId',
      scope: 'FlutterBlueReceiverTransport',
    );
    await _stopNativeScanIfNeeded();
    final device = _known[remoteId] ?? BluetoothDevice.fromId(remoteId);
    _known[remoteId] = device;
    if (!device.isConnected) {
      await device.connect(timeout: const Duration(seconds: 12));
    }
    ReceiverLogging.link(
      'gatt connected; bind io remoteId=${device.remoteId.str}',
      scope: 'FlutterBlueReceiverTransport',
    );
    try {
      await _bindIoCharacteristic(device);
    } catch (error, stackTrace) {
      if (!isGattInvalidHandleError(error)) {
        rethrow;
      }
      ReceiverLogging.link(
        'invalid gatt handle; clear cache and retry once '
        'remoteId=${device.remoteId.str}',
        scope: 'FlutterBlueReceiverTransport',
      );
      try {
        await refreshReceiverGattConnection(device);
        ReceiverLogging.link(
          'gatt cache retry connected; rediscover services '
          'remoteId=${device.remoteId.str}',
          scope: 'FlutterBlueReceiverTransport',
        );
      } catch (recoveryError, recoveryStackTrace) {
        ReceiverLogging.link(
          'gatt cache recovery failed remoteId=${device.remoteId.str} '
          'error=$recoveryError\n$recoveryStackTrace',
          scope: 'FlutterBlueReceiverTransport',
        );
        Error.throwWithStackTrace(error, stackTrace);
      }
      ReceiverLogging.link(
        'gatt cache retry; bind io remoteId=${device.remoteId.str}',
        scope: 'FlutterBlueReceiverTransport',
      );
      await _bindIoCharacteristic(device);
    }
  }

  @override
  Future<void> disconnect(String remoteId) async {
    ReceiverLogging.link(
      'disconnect remoteId=$remoteId',
      scope: 'FlutterBlueReceiverTransport',
    );
    final device = _known[remoteId];
    if (device == null) {
      return;
    }
    await _notifySub?.cancel();
    _notifySub = null;
    _activeDevice = null;
    _writeCharacteristic = null;
    await device.disconnect();
  }

  @override
  Future<int> readRssi(String remoteId) {
    final device = _known[remoteId] ?? BluetoothDevice.fromId(remoteId);
    return device.readRssi(timeout: 3);
  }

  @override
  Future<void> send(
    List<int> bytes, {
    bool preferWithoutResponse = false,
  }) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      throw StateError('bluetooth write characteristic is not ready');
    }
    // 常规调试记录失控保护和退出蓝牙模式；升级排查时额外记录升级命令原始帧。
    if (_isLoggedProtocolFrame(bytes)) {
      ReceiverLogging.transmittedBytes(
        bytes,
        scope: 'FlutterBlueReceiverTransport',
      );
    }
    _lastSentBytes = List<int>.from(bytes, growable: false);
    final mtu = _activeDevice?.mtuNow ?? 23;
    final chunkSize = (mtu - 3).clamp(1, bytes.length);
    final withoutResponse =
        characteristic.properties.writeWithoutResponse &&
        (preferWithoutResponse || !characteristic.properties.write);
    for (var i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize > bytes.length) ? bytes.length : i + chunkSize;
      await characteristic.write(
        bytes.sublist(i, end),
        withoutResponse: withoutResponse,
      );
    }
  }

  @override
  Future<bool> turnOnAdapter() async {
    try {
      await FlutterBluePlus.turnOn();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _bindIoCharacteristic(BluetoothDevice device) async {
    ReceiverLogging.link(
      'bind io characteristic remoteId=${device.remoteId.str}',
      scope: 'FlutterBlueReceiverTransport',
    );
    final services = await device.discoverServices();
    final customPair = findCustomReceiverIoPair(services);
    final writeCandidates = <BluetoothCharacteristic>[];
    final notifyCandidates = <BluetoothCharacteristic>[];
    BluetoothCharacteristic? duplex;
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        ReceiverLogging.link(
          'service=${service.serviceUuid.str} '
          'char=${characteristic.characteristicUuid.str} '
          'props('
          'read=${characteristic.properties.read},'
          'write=${characteristic.properties.write},'
          'writeNoRsp=${characteristic.properties.writeWithoutResponse},'
          'notify=${characteristic.properties.notify},'
          'indicate=${characteristic.properties.indicate}'
          ') '
          'descriptors=${characteristic.descriptors.map((d) => d.descriptorUuid.str).join(",")}',
          scope: 'FlutterBlueReceiverTransport',
        );
        final canNotify =
            characteristic.properties.notify ||
            characteristic.properties.indicate;
        final canWrite =
            characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse;
        if (canWrite) {
          writeCandidates.add(characteristic);
        }
        if (canNotify) {
          notifyCandidates.add(characteristic);
        }
        if (canNotify &&
            canWrite &&
            !isSystemBleService(characteristic.serviceUuid.str)) {
          duplex ??= characteristic;
        }
      }
    }
    final writeTarget =
        customPair?.write ??
        duplex ??
        pickReceiverIoCharacteristic(writeCandidates);
    final notifyTarget =
        customPair?.notify ??
        duplex ??
        pickReceiverIoCharacteristic(
          notifyCandidates,
          preferredService: writeTarget?.serviceUuid.str,
          preferCccd: true,
        );
    if (writeTarget == null || notifyTarget == null) {
      throw StateError(
        'no io characteristics found (write=${writeCandidates.length}, notify=${notifyCandidates.length})',
      );
    }
    if (customPair != null) {
      ReceiverLogging.link(
        'prefer custom io pair write=${writeTarget.characteristicUuid.str} '
        'notify=${notifyTarget.characteristicUuid.str}',
        scope: 'FlutterBlueReceiverTransport',
      );
    }
    try {
      await notifyTarget.setNotifyValue(true);
    } catch (error, stackTrace) {
      ReceiverLogging.link(
        'enable notify failed remoteId=${device.remoteId.str} '
        'char=${notifyTarget.characteristicUuid.str} '
        'error=$error\n$stackTrace',
        scope: 'FlutterBlueReceiverTransport',
      );
      rethrow;
    }
    ReceiverLogging.link(
      'notify enabled=${notifyTarget.isNotifying}',
      scope: 'FlutterBlueReceiverTransport',
    );
    await _notifySub?.cancel();
    _notifySub = notifyTarget.onValueReceived.listen((value) {
      if (value.isNotEmpty) {
        final possibleEcho =
            _lastSentBytes != null &&
            _lastSentBytes!.length == value.length &&
            _sameBytes(_lastSentBytes!, value);
        final command = _frameCommand(value);
        // 回显过滤前记录原始入站数据，避免 0x07 回显被误判时无法排查。
        if (_isLoggedProtocolFrame(value)) {
          ReceiverLogging.receiver(
            'rx bytes(${value.length}) ${ReceiverLogging.hexBytes(value)}',
            scope: 'FlutterBlueReceiverTransport',
          );
        }
        // 失控保护读取/设置及升级长度的设备应答可能与请求帧完全相同。
        final useEchoAsProtocolReply =
            possibleEcho && shouldUseReceiverEchoAsProtocolReply(command);
        if (possibleEcho && !useEchoAsProtocolReply) {
          return;
        }
        _incomingCtrl.add(value);
      }
    });
    ReceiverLogging.link(
      'io write=${writeTarget.characteristicUuid.str} notify=${notifyTarget.characteristicUuid.str}',
      scope: 'FlutterBlueReceiverTransport',
    );
    _activeDevice = device;
    _writeCharacteristic = writeTarget;
  }

  AdapterState _mapAdapterState(BluetoothAdapterState state) {
    final mapped = switch (state) {
      BluetoothAdapterState.unknown => AdapterState.unknown,
      BluetoothAdapterState.off => AdapterState.off,
      BluetoothAdapterState.turningOn => AdapterState.turningOn,
      BluetoothAdapterState.on => AdapterState.on,
      BluetoothAdapterState.turningOff => AdapterState.turningOff,
      BluetoothAdapterState.unauthorized => AdapterState.unauthorized,
      BluetoothAdapterState.unavailable => AdapterState.unsupported,
    };
    _adapterState = mapped;
    return mapped;
  }

  ReceiverLinkConnectionEvent _mapConnectionEvent(
    OnConnectionStateChangedEvent event,
  ) {
    final remoteId = event.device.remoteId.str;
    _known[remoteId] = event.device;
    if (event.connectionState == BluetoothConnectionState.disconnected &&
        _activeDevice?.remoteId.str == remoteId) {
      unawaited(_notifySub?.cancel());
      _notifySub = null;
      _activeDevice = null;
      _writeCharacteristic = null;
    }
    return ReceiverLinkConnectionEvent(
      remoteId: remoteId,
      state: event.connectionState == BluetoothConnectionState.connected
          ? ReceiverLinkConnectionState.connected
          : ReceiverLinkConnectionState.disconnected,
    );
  }

  List<ReceiverBluetoothScanDevice> _mapScanResults(List<ScanResult> results) {
    final mapped = results
        .map((result) {
          final remoteId = result.device.remoteId.str;
          _known[remoteId] = result.device;
          final name = result.device.platformName.isNotEmpty
              ? result.device.platformName
              : result.advertisementData.advName;
          return ReceiverBluetoothScanDevice(
            remoteId: remoteId,
            name: name.isEmpty ? remoteId : name,
            rssi: result.rssi,
            connected: result.device.isConnected,
          );
        })
        .toList(growable: false);
    if (mapped.isNotEmpty) {
      ReceiverLogging.link(
        'scan results=${mapped.length} first=${mapped.first.remoteId}/${mapped.first.rssi}',
        scope: 'FlutterBlueReceiverTransport',
      );
    }
    return mapped;
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

  Never _handleScanStreamError(Object error, StackTrace stackTrace) {
    ReceiverLogging.link(
      'scan stream error: $error',
      scope: 'FlutterBlueReceiverTransport',
    );
    _isScanning = false;
    _lastScanStopAt = DateTime.now();
    throw error;
  }

  Future<void> _stopNativeScanIfNeeded() async {
    if (!FlutterBluePlus.isScanningNow) {
      return;
    }
    try {
      await FlutterBluePlus.stopScan();
    } catch (error) {
      ReceiverLogging.link(
        'pre-start stopScan failed: $error',
        scope: 'FlutterBlueReceiverTransport',
      );
    }
    _isScanning = false;
    _lastScanStopAt = DateTime.now();
  }

  bool _sameBytes(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  /// 判断数据是否属于当前调试开关要求记录的协议帧。
  bool _isLoggedProtocolFrame(List<int> bytes) {
    if (bytes.length < 3 || bytes.first != 0xFA) {
      return false;
    }
    final command = bytes[2] & 0xFF;
    if (command == 0x07 || command == 0x08 || command == 0x20) {
      return true;
    }
    return ReceiverLogging.upgradeEnabled && command >= 0x11 && command <= 0x13;
  }

  int? _frameCommand(List<int> bytes) {
    if (bytes.length < 3 || bytes.first != 0xFA) {
      return null;
    }
    return bytes[2] & 0xFF;
  }
}

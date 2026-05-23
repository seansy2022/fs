import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'receiver_link_transport.dart';
import 'receiver_logging.dart';

class FlutterBlueReceiverTransport implements ReceiverBluetoothTransport {
  FlutterBlueReceiverTransport({LogLevel logLevel = LogLevel.none}) {
    unawaited(FlutterBluePlus.setLogLevel(logLevel));
  }

  final Map<String, BluetoothDevice> _known = <String, BluetoothDevice>{};
  final StreamController<List<int>> _incomingCtrl =
      StreamController<List<int>>.broadcast();
  StreamSubscription<List<int>>? _notifySub;
  BluetoothDevice? _activeDevice;
  BluetoothCharacteristic? _writeCharacteristic;
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
  Stream<List<ReceiverBluetoothScanDevice>> get scanResults {
    return FlutterBluePlus.scanResults
        .handleError(_handleScanStreamError)
        .map(_mapScanResults);
  }

  @override
  Stream<List<int>> get incomingBytes => _incomingCtrl.stream;

  @override
  Future<void> startScan() {
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
        await FlutterBluePlus.startScan();
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
    final device = _known[remoteId];
    if (device == null) {
      throw StateError('unknown bluetooth device: $remoteId');
    }
    if (!device.isConnected) {
      await device.connect(timeout: const Duration(seconds: 12));
    }
    await _bindIoCharacteristic(device);
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
  Future<void> send(List<int> bytes) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      throw StateError('bluetooth write characteristic is not ready');
    }
    ReceiverLogging.link(
      'tx bytes(${bytes.length}) ${ReceiverLogging.hexBytes(bytes)}',
      scope: 'FlutterBlueReceiverTransport',
    );
    final mtu = _activeDevice?.mtuNow ?? 23;
    final chunkSize = (mtu - 3).clamp(1, bytes.length);
    final withoutResponse =
        characteristic.properties.writeWithoutResponse &&
        !characteristic.properties.write;
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
    final writeCandidates = <BluetoothCharacteristic>[];
    final notifyCandidates = <BluetoothCharacteristic>[];
    BluetoothCharacteristic? duplex;
    for (final service in services) {
      for (final characteristic in service.characteristics) {
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
            !_isSystemService(characteristic.serviceUuid.str)) {
          duplex ??= characteristic;
        }
      }
    }
    final writeTarget = duplex ?? _pickIoCharacteristic(writeCandidates);
    final notifyTarget =
        duplex ??
        _pickIoCharacteristic(
          notifyCandidates,
          preferredService: writeTarget?.serviceUuid.str,
          preferCccd: true,
        );
    if (writeTarget == null || notifyTarget == null) {
      throw StateError(
        'no io characteristics found (write=${writeCandidates.length}, notify=${notifyCandidates.length})',
      );
    }
    await notifyTarget.setNotifyValue(true);
    await _notifySub?.cancel();
    _notifySub = notifyTarget.onValueReceived.listen((value) {
      if (value.isNotEmpty) {
        ReceiverLogging.link(
          'rx bytes(${value.length}) ${ReceiverLogging.hexBytes(value)}',
          scope: 'FlutterBlueReceiverTransport',
        );
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

  BluetoothCharacteristic? _pickIoCharacteristic(
    List<BluetoothCharacteristic> candidates, {
    String? preferredService,
    bool preferCccd = false,
  }) {
    if (candidates.isEmpty) {
      return null;
    }
    BluetoothCharacteristic? best;
    var bestScore = -1;
    for (final c in candidates) {
      var score = 0;
      if (!_isSystemService(c.serviceUuid.str)) {
        score += 100;
      }
      if (preferredService != null && c.serviceUuid.str == preferredService) {
        score += 50;
      }
      if (preferCccd && _hasCccd(c)) {
        score += 20;
      }
      if (score > bestScore) {
        best = c;
        bestScore = score;
      }
    }
    return best;
  }

  bool _isSystemService(String uuid) {
    final v = uuid.toLowerCase();
    return v == '00001800-0000-1000-8000-00805f9b34fb' ||
        v == '00001801-0000-1000-8000-00805f9b34fb';
  }

  bool _hasCccd(BluetoothCharacteristic characteristic) {
    for (final d in characteristic.descriptors) {
      if (d.descriptorUuid.str.toLowerCase() ==
          '00002902-0000-1000-8000-00805f9b34fb') {
        return true;
      }
    }
    return false;
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
}

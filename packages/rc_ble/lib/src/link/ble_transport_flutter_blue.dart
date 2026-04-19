import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../logging/rc_logging.dart';
import 'link_transport.dart';

class FlutterBlueTransport implements BluetoothTransport {
  final Map<String, BluetoothDevice> _known = <String, BluetoothDevice>{};
  final StreamController<List<int>> _incomingCtrl =
      StreamController.broadcast();
  StreamSubscription<List<int>>? _notifySub;
  BluetoothDevice? _activeDevice;
  BluetoothCharacteristic? _writeCharacteristic;

  @override
  LinkType get type => LinkType.ble;

  @override
  Stream<List<BluetoothScanDevice>> get scanResults {
    return FlutterBluePlus.scanResults.map(_mapScanResults);
  }

  @override
  Stream<List<int>> get incomingBytes => _incomingCtrl.stream;

  @override
  Future<void> startScan() {
    RcLogging.link('startScan continuous', scope: 'FlutterBlueTransport');
    return FlutterBluePlus.startScan();
  }

  @override
  Future<void> stopScan() {
    RcLogging.link('stopScan', scope: 'FlutterBlueTransport');
    return FlutterBluePlus.stopScan();
  }

  @override
  Future<void> connect(String remoteId) async {
    RcLogging.link('connect remoteId=$remoteId', scope: 'FlutterBlueTransport');
    final device = _known[remoteId];
    if (device == null) throw StateError('unknown bluetooth device: $remoteId');
    if (!device.isConnected) {
      await device.connect(timeout: const Duration(seconds: 12));
    }
    await _bindIoCharacteristic(device);
  }

  @override
  Future<void> disconnect(String remoteId) async {
    RcLogging.link(
      'disconnect remoteId=$remoteId',
      scope: 'FlutterBlueTransport',
    );
    final device = _known[remoteId];
    if (device == null) return;
    await _notifySub?.cancel();
    _notifySub = null;
    _activeDevice = null;
    _writeCharacteristic = null;
    await device.disconnect();
  }

  @override
  Future<void> send(List<int> bytes) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      throw StateError('bluetooth write characteristic is not ready');
    }
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

  Future<void> _bindIoCharacteristic(BluetoothDevice device) async {
    RcLogging.link(
      'bind io characteristic remoteId=${device.remoteId.str}',
      scope: 'FlutterBlueTransport',
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
        if (canWrite) writeCandidates.add(characteristic);
        if (canNotify) notifyCandidates.add(characteristic);
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
        _incomingCtrl.add(value);
      }
    });
    RcLogging.link(
      'io write=${writeTarget.characteristicUuid.str} notify=${notifyTarget.characteristicUuid.str}',
      scope: 'FlutterBlueTransport',
    );
    _activeDevice = device;
    _writeCharacteristic = writeTarget;
  }

  BluetoothCharacteristic? _pickIoCharacteristic(
    List<BluetoothCharacteristic> candidates, {
    String? preferredService,
    bool preferCccd = false,
  }) {
    if (candidates.isEmpty) return null;
    BluetoothCharacteristic? best;
    var bestScore = -1;
    for (final c in candidates) {
      var score = 0;
      if (!_isSystemService(c.serviceUuid.str)) score += 100;
      if (preferredService != null && c.serviceUuid.str == preferredService) {
        score += 50;
      }
      if (preferCccd && _hasCccd(c)) score += 20;
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

  List<BluetoothScanDevice> _mapScanResults(List<ScanResult> results) {
    final mapped = results.map((result) {
      final remoteId = result.device.remoteId.str;
      _known[remoteId] = result.device;
      final name = result.device.platformName.isNotEmpty
          ? result.device.platformName
          : result.advertisementData.advName;
      return BluetoothScanDevice(
        remoteId: remoteId,
        name: name.isEmpty ? remoteId : name,
        rssi: result.rssi,
      );
    }).toList();
    if (mapped.isNotEmpty) {
      RcLogging.link(
        'scan results=${mapped.length} first=${mapped.first.remoteId}/${mapped.first.rssi}',
        scope: 'FlutterBlueTransport',
      );
    }
    return mapped;
  }
}

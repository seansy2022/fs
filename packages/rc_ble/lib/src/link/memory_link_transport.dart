import 'dart:async';

import 'link_transport.dart';

class MemoryLinkTransport implements LinkTransport {
  MemoryLinkTransport({this.linkType = LinkType.ble});

  final LinkType linkType;
  final StreamController<List<BluetoothScanDevice>> _scanCtrl =
      StreamController.broadcast();
  final StreamController<List<int>> _incomingCtrl =
      StreamController.broadcast();
  final List<List<int>> sentPackets = <List<int>>[];
  bool scanning = false;
  bool connected = false;
  String? connectedRemoteId;

  @override
  LinkType get type => linkType;

  @override
  Stream<List<BluetoothScanDevice>> get scanResults => _scanCtrl.stream;

  @override
  Stream<List<int>> get incomingBytes => _incomingCtrl.stream;

  @override
  Future<void> connect(String remoteId) async {
    connected = true;
    connectedRemoteId = remoteId;
  }

  @override
  Future<void> disconnect(String remoteId) async {
    connected = false;
    connectedRemoteId = null;
  }

  @override
  Future<void> send(List<int> bytes) async {
    sentPackets.add(List<int>.from(bytes));
  }

  @override
  Future<void> startScan() async {
    scanning = true;
  }

  @override
  Future<void> stopScan() async {
    scanning = false;
  }

  void emitScanResults(List<BluetoothScanDevice> devices) {
    _scanCtrl.add(devices);
  }

  void emitIncoming(List<int> bytes) {
    _incomingCtrl.add(bytes);
  }

  Future<void> dispose() async {
    await _scanCtrl.close();
    await _incomingCtrl.close();
  }
}

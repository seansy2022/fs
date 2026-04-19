class BluetoothScanDevice {
  const BluetoothScanDevice({
    required this.remoteId,
    required this.name,
    required this.rssi,
  });

  final String remoteId;
  final String name;
  final int rssi;
}

enum LinkType { ble, usb }

abstract class LinkTransport {
  LinkType get type;

  Stream<List<BluetoothScanDevice>> get scanResults;

  Stream<List<int>> get incomingBytes;

  Future<void> startScan();

  Future<void> stopScan();

  Future<void> connect(String remoteId);

  Future<void> disconnect(String remoteId);

  Future<void> send(List<int> bytes);
}

typedef BluetoothTransport = LinkTransport;

abstract class UsbTransport implements LinkTransport {}

class UnsupportedUsbTransport implements UsbTransport {
  @override
  LinkType get type => LinkType.usb;

  @override
  Stream<List<BluetoothScanDevice>> get scanResults => const Stream.empty();

  @override
  Stream<List<int>> get incomingBytes => const Stream.empty();

  @override
  Future<void> connect(String remoteId) {
    throw UnimplementedError('usb transport is not implemented');
  }

  @override
  Future<void> disconnect(String remoteId) async {}

  @override
  Future<void> send(List<int> bytes) {
    throw UnimplementedError('usb transport is not implemented');
  }

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}
}

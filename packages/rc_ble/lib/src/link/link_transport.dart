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

/// Phone Bluetooth adapter state.
enum AdapterState { unknown, off, turningOn, on, turningOff, unauthorized, unsupported }

abstract class LinkTransport {
  LinkType get type;

  Stream<List<BluetoothScanDevice>> get scanResults;

  Stream<List<int>> get incomingBytes;

  /// Stream of phone Bluetooth adapter state changes.
  Stream<AdapterState> get adapterState;

  /// Current snapshot of the adapter state.
  AdapterState get currentAdapterState;

  Future<void> startScan();

  Future<void> stopScan();

  /// Request the phone to turn Bluetooth on.
  /// Returns true if the request was made; on some platforms the user must
  /// grant permission via a system dialog.
  Future<bool> turnOnAdapter();

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
  AdapterState get currentAdapterState => AdapterState.unsupported;

  @override
  Stream<AdapterState> get adapterState =>
      Stream<AdapterState>.value(AdapterState.unsupported);

  @override
  Future<bool> turnOnAdapter() async => false;

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

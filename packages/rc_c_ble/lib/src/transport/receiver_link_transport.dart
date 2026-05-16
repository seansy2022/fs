class ReceiverBluetoothScanDevice {
  const ReceiverBluetoothScanDevice({
    required this.remoteId,
    required this.name,
    required this.rssi,
  });

  final String remoteId;
  final String name;
  final int rssi;
}

enum ReceiverLinkType { ble, usb }

enum AdapterState {
  unknown,
  off,
  turningOn,
  on,
  turningOff,
  unauthorized,
  unsupported,
}

abstract class ReceiverLinkTransport {
  ReceiverLinkType get type;

  Stream<List<ReceiverBluetoothScanDevice>> get scanResults;

  Stream<List<int>> get incomingBytes;

  Stream<AdapterState> get adapterState;

  AdapterState get currentAdapterState;

  Future<void> startScan();

  Future<void> stopScan();

  Future<bool> turnOnAdapter();

  Future<void> connect(String remoteId);

  Future<void> disconnect(String remoteId);

  Future<int> readRssi(String remoteId);

  Future<void> send(List<int> bytes);
}

typedef ReceiverBluetoothTransport = ReceiverLinkTransport;

typedef BluetoothScanDevice = ReceiverBluetoothScanDevice;
typedef LinkTransport = ReceiverLinkTransport;
typedef BluetoothTransport = ReceiverBluetoothTransport;
typedef LinkType = ReceiverLinkType;

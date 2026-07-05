class ReceiverBluetoothScanDevice {
  const ReceiverBluetoothScanDevice({
    required this.remoteId,
    required this.name,
    required this.rssi,
    this.connected = false,
  });

  final String remoteId;
  final String name;
  final int rssi;
  final bool connected;
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

enum ReceiverLinkConnectionState { connected, disconnected }

class ReceiverLinkConnectionEvent {
  const ReceiverLinkConnectionEvent({
    required this.remoteId,
    required this.state,
  });

  final String remoteId;
  final ReceiverLinkConnectionState state;
}

abstract class ReceiverLinkTransport {
  ReceiverLinkType get type;

  Stream<List<ReceiverBluetoothScanDevice>> get scanResults;

  Stream<List<int>> get incomingBytes;

  Stream<AdapterState> get adapterState;

  Stream<ReceiverLinkConnectionEvent> get connectionEvents;

  AdapterState get currentAdapterState;

  Future<void> startScan({List<String>? withRemoteIds, Duration? timeout});

  Future<void> stopScan();

  Future<bool> turnOnAdapter();

  Future<void> connect(String remoteId);

  Future<void> disconnect(String remoteId);

  Future<int> readRssi(String remoteId);

  Future<void> send(List<int> bytes, {bool preferWithoutResponse = false});
}

typedef ReceiverBluetoothTransport = ReceiverLinkTransport;

typedef BluetoothScanDevice = ReceiverBluetoothScanDevice;
typedef LinkTransport = ReceiverLinkTransport;
typedef BluetoothTransport = ReceiverBluetoothTransport;
typedef LinkType = ReceiverLinkType;

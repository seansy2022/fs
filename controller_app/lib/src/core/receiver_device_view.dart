import 'package:rc_c_ble/rc_c_ble.dart';

class ReceiverDeviceView {
  const ReceiverDeviceView({
    required this.remoteId,
    required this.name,
    required this.isConnected,
    required this.isRemembered,
    required this.isOnline,
    required this.rssi,
    this.scanDevice,
  });

  final String remoteId;
  final String name;
  final bool isConnected;
  final bool isRemembered;
  final bool isOnline;
  final int? rssi;
  final ReceiverScanDevice? scanDevice;

  bool get hasExplicitName {
    final advertisedName = scanDevice?.name.trim() ?? '';
    if (advertisedName.isNotEmpty) {
      return true;
    }
    return name.trim().isNotEmpty && name.trim() != remoteId;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ReceiverDeviceView &&
        other.remoteId == remoteId &&
        other.name == name &&
        other.isConnected == isConnected &&
        other.isRemembered == isRemembered &&
        other.isOnline == isOnline &&
        other.rssi == rssi &&
        _sameScanDevice(other.scanDevice, scanDevice);
  }

  @override
  int get hashCode => Object.hash(
    remoteId,
    name,
    isConnected,
    isRemembered,
    isOnline,
    rssi,
    scanDevice?.remoteId,
    scanDevice?.name,
    scanDevice?.rssi,
    scanDevice?.connected,
  );
}

bool shouldIncludeBluetoothDevice(ReceiverScanDevice device) {
  return device.name.trim().startsWith('R4');
}

String preferredBluetoothDeviceName(
  String? currentName, {
  String? rememberedName,
  required String fallbackRemoteId,
}) {
  final scanName = currentName?.trim() ?? '';
  if (scanName.isNotEmpty && scanName != fallbackRemoteId) {
    return scanName;
  }
  final historyName = rememberedName?.trim() ?? '';
  if (historyName.isNotEmpty) {
    return historyName;
  }
  if (scanName.isNotEmpty) {
    return scanName;
  }
  return fallbackRemoteId;
}

bool _sameScanDevice(ReceiverScanDevice? left, ReceiverScanDevice? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null) {
    return false;
  }
  return left.remoteId == right.remoteId &&
      left.name == right.name &&
      left.rssi == right.rssi &&
      left.connected == right.connected;
}

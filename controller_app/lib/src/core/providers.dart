import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../features/bluetooth/controllers/device_history_controller.dart';
export '../provider/app_settings_provider.dart';

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

final receiverRepositoryProvider = Provider<ReceiverRepository>((ref) {
  final client = ReceiverBleClient();
  final repository = ReceiverRepository(client: client);
  ref.onDispose(() async {
    await repository.dispose();
  });
  return repository;
});

final receiverConnectionProvider = StreamProvider<ReceiverConnectionState>((
  ref,
) {
  return ref.watch(receiverRepositoryProvider).connectionStateStream;
});

final receiverInfoProvider = StreamProvider<ReceiverInfo?>((ref) {
  return ref.watch(receiverRepositoryProvider).receiverInfoStream;
});

final connectedRssiProvider = StreamProvider<int?>((ref) {
  return ref.watch(receiverRepositoryProvider).connectedRssiStream;
});

final receiverDevicesProvider = StreamProvider<List<ReceiverScanDevice>>((ref) {
  return ref.watch(receiverRepositoryProvider).scanResultsStream;
});

final adapterStateProvider = StreamProvider<AdapterState>((ref) {
  return ref.watch(receiverRepositoryProvider).adapterStateStream;
});

final receiverFirmwareInfoProvider = StreamProvider<ReceiverFirmwareInfo?>((
  ref,
) {
  return ref.watch(receiverRepositoryProvider).firmwareInfoStream;
});

final rememberedDevicesProvider =
    StateNotifierProvider<DeviceHistoryController, List<RememberedReceiver>>((
      ref,
    ) {
      return DeviceHistoryController();
    });

final scanSessionDevicesProvider = Provider<List<ReceiverDeviceView>>((ref) {
  final scanned = ref
      .watch(receiverDevicesProvider)
      .maybeWhen(
        data: (devices) => devices,
        orElse: () => const <ReceiverScanDevice>[],
      )
      .where(shouldIncludeBluetoothDevice)
      .toList(growable: false);
  final rememberedIds = ref
      .watch(rememberedDevicesProvider)
      .map((device) => device.remoteId)
      .toSet();

  return scanned
      .map(
        (device) => ReceiverDeviceView(
          remoteId: device.remoteId,
          name: preferredBluetoothDeviceName(
            device.name,
            fallbackRemoteId: device.remoteId,
          ),
          isConnected: device.connected,
          isRemembered: rememberedIds.contains(device.remoteId),
          isOnline: device.rssi > -120,
          rssi: device.rssi,
          scanDevice: device,
        ),
      )
      .toList(growable: false);
});

final pairedReceiverDevicesProvider = Provider<List<ReceiverDeviceView>>((ref) {
  final remembered = ref.watch(rememberedDevicesProvider);
  final scanned = ref
      .watch(receiverDevicesProvider)
      .maybeWhen(
        data: (devices) => devices,
        orElse: () => const <ReceiverScanDevice>[],
      );
  final receiverInfo = ref.watch(receiverInfoProvider).valueOrNull;
  final scannedMap = <String, ReceiverScanDevice>{
    for (final device in scanned) device.remoteId: device,
  };
  String? connectedIdFromScan;
  for (final device in scanned) {
    if (device.connected) {
      connectedIdFromScan = device.remoteId;
      break;
    }
  }

  final connectedId = receiverInfo?.remoteId ?? connectedIdFromScan;

  return remembered
      .map((entry) {
        final scan = scannedMap[entry.remoteId];
        final isConnected =
            scan?.connected == true || connectedId == entry.remoteId;
        return ReceiverDeviceView(
          remoteId: entry.remoteId,
          name: preferredBluetoothDeviceName(
            scan?.name,
            rememberedName: entry.name,
            fallbackRemoteId: entry.remoteId,
          ),
          isConnected: isConnected,
          isRemembered: true,
          isOnline: (scan?.rssi ?? -127) > -120,
          rssi: scan?.rssi,
          scanDevice: scan,
        );
      })
      .toList(growable: false);
});

final mergedReceiverDevicesProvider = Provider<List<ReceiverScanDevice>>((ref) {
  final scanned = ref
      .watch(receiverDevicesProvider)
      .maybeWhen(
        data: (devices) => devices,
        orElse: () => const <ReceiverScanDevice>[],
      );
  final remembered = ref.watch(rememberedDevicesProvider);
  final merged = <String, ReceiverScanDevice>{
    for (final device in scanned) device.remoteId: device,
  };
  for (final device in remembered) {
    merged.putIfAbsent(
      device.remoteId,
      () => ReceiverScanDevice(
        remoteId: device.remoteId,
        name: preferredBluetoothDeviceName(
          device.name,
          fallbackRemoteId: device.remoteId,
        ),
        rssi: -127,
      ),
    );
  }
  // Build a lookup map for last-used timestamps.
  final lastUsed = <String, DateTime>{
    for (final r in remembered) r.remoteId: r.lastUsedAt,
  };
  final results = merged.values.toList(growable: false);
  results.sort((left, right) {
    final leftScore = _deviceScore(left);
    final rightScore = _deviceScore(right);
    if (leftScore != rightScore) {
      return leftScore.compareTo(rightScore);
    }
    // Same score group: sort by last used time descending.
    final leftTime =
        lastUsed[left.remoteId] ?? DateTime.fromMillisecondsSinceEpoch(0);
    final rightTime =
        lastUsed[right.remoteId] ?? DateTime.fromMillisecondsSinceEpoch(0);
    return rightTime.compareTo(leftTime);
  });
  return results;
});

int _deviceScore(ReceiverScanDevice device) {
  if (device.connected) {
    return 0;
  }
  if (device.rssi > -120) {
    return 1;
  }
  return 2;
}

bool shouldIncludeBluetoothDevice(ReceiverScanDevice device) {
  return true;
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

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../features/bluetooth/controllers/device_history_controller.dart';
import '../features/control/controllers/control_controller.dart';
import '../features/control/providers/gyro_prompt_provider.dart';
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

final controlControllerProvider =
    StateNotifierProvider.autoDispose<ControlController, ControlScreenState>((
      ref,
    ) {
      final controller = ControlController(
        ref,
        ref.watch(receiverRepositoryProvider),
      );
      ref.listen<AsyncValue<GyroPrompt>>(gyroPromptProvider, (_, next) {
        next.whenData((value) {
          if (!controller.state.gyroEnabled) {
            return;
          }
          unawaited(
            controller.setGyroPrompt(
              steering: value.steering,
              throttle: value.throttle,
            ),
          );
        });
      });
      return controller;
    });

final scanSessionDevicesProvider = Provider<List<ReceiverDeviceView>>((ref) {
  final scanned = ref
      .watch(receiverDevicesProvider)
      .maybeWhen(
        data: (devices) => devices,
        orElse: () => const <ReceiverScanDevice>[],
      )
      .where((device) => device.name.trim().isNotEmpty)
      .toList(growable: false);
  final rememberedIds = ref
      .watch(rememberedDevicesProvider)
      .map((device) => device.remoteId)
      .toSet();

  return scanned
      .map(
        (device) => ReceiverDeviceView(
          remoteId: device.remoteId,
          name: device.name,
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
          name: entry.name,
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
        name: device.name,
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

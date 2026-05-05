import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ble/rc_ble.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../features/bluetooth/controllers/device_history_controller.dart';
import '../features/control/controllers/control_controller.dart';
import '../features/settings/controllers/settings_controller.dart';
import '../features/settings/models/app_settings_state.dart';

final receiverRepositoryProvider = Provider<ReceiverRepository>((ref) {
  final transport = MockProtocolLinkTransport();
  final client = ReceiverBleClient(transport: transport);
  final repository = ReceiverRepository(client: client);
  ref.onDispose(() async {
    await transport.dispose();
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

final appSettingsProvider =
    StateNotifierProvider<SettingsController, AppSettingsState>((ref) {
      return SettingsController();
    });

final controlControllerProvider =
    StateNotifierProvider.autoDispose<ControlController, ControlScreenState>((
      ref,
    ) {
      return ControlController(ref.watch(receiverRepositoryProvider));
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
    final leftTime = lastUsed[left.remoteId] ?? DateTime.fromMillisecondsSinceEpoch(0);
    final rightTime = lastUsed[right.remoteId] ?? DateTime.fromMillisecondsSinceEpoch(0);
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

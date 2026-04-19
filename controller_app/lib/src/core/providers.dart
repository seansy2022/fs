import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../features/bluetooth/controllers/device_history_controller.dart';
import '../features/control/controllers/control_controller.dart';
import '../features/settings/controllers/settings_controller.dart';
import '../features/settings/models/app_settings_state.dart';

final receiverRepositoryProvider = Provider<ReceiverRepository>((ref) {
  final repository = ReceiverRepository();
  ref.onDispose(() {
    unawaited(repository.dispose());
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
  final results = merged.values.toList(growable: false);
  results.sort((left, right) {
    final leftScore = _deviceScore(left);
    final rightScore = _deviceScore(right);
    if (leftScore != rightScore) {
      return leftScore.compareTo(rightScore);
    }
    return right.rssi.compareTo(left.rssi);
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

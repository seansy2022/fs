import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';

import '../types.dart';
import 'app_state_provider.dart';

final bluetoothTransportProvider = linkTransportProvider;

class BluetoothController extends Notifier<BluetoothSettings> {
  @override
  BluetoothSettings build() {
    return ref.watch(rcAppStateProvider.select((state) => state.bluetooth));
  }

  void startScan() => ref.read(rcAppStateProvider.notifier).startScan();

  void toggleConnection(int id) {
    ref.read(rcAppStateProvider.notifier).toggleConnection(id);
  }
}

final bluetoothProvider =
    NotifierProvider<BluetoothController, BluetoothSettings>(
      BluetoothController.new,
    );

final bluetoothDevicesProvider = Provider<List<BluetoothDevice>>((ref) {
  return ref.watch(bluetoothProvider.select((state) => state.devices));
});

final bluetoothScanningProvider = Provider<bool>((ref) {
  return ref.watch(bluetoothProvider.select((state) => state.isScanning));
});

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ble/rc_ble.dart';

class BluetoothLogState {
  const BluetoothLogState({
    required this.loading,
    required this.enabled,
    required this.logs,
  });

  factory BluetoothLogState.initial() {
    return const BluetoothLogState(
      loading: true,
      enabled: false,
      logs: <BluetoothLogEntry>[],
    );
  }

  final bool loading;
  final bool enabled;
  final List<BluetoothLogEntry> logs;

  BluetoothLogState copyWith({
    bool? loading,
    bool? enabled,
    List<BluetoothLogEntry>? logs,
  }) {
    return BluetoothLogState(
      loading: loading ?? this.loading,
      enabled: enabled ?? this.enabled,
      logs: logs ?? this.logs,
    );
  }
}

final bluetoothLogStoreProvider = Provider<BluetoothLogStore>((_) {
  return bluetoothLogStore;
});

class BluetoothLogController extends Notifier<BluetoothLogState> {
  @override
  BluetoothLogState build() {
    unawaited(_load());
    return BluetoothLogState.initial();
  }

  Future<void> refresh() async {
    final store = ref.read(bluetoothLogStoreProvider);
    final logs = await store.listAllAsc();
    state = state.copyWith(loading: false, logs: logs);
  }

  Future<void> setEnabled(bool enabled) async {
    final store = ref.read(bluetoothLogStoreProvider);
    await store.setEnabled(enabled);
    state = state.copyWith(enabled: enabled);
  }

  Future<void> _load() async {
    final store = ref.read(bluetoothLogStoreProvider);
    await store.init();
    final enabled = await store.isEnabled();
    final logs = await store.listAllAsc();
    state = state.copyWith(loading: false, enabled: enabled, logs: logs);
  }
}

final bluetoothLogProvider =
    NotifierProvider<BluetoothLogController, BluetoothLogState>(
      BluetoothLogController.new,
    );

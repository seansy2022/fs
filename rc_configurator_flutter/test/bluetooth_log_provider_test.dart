import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/provider/bluetooth_log_provider.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  test('bluetooth log provider loads and toggles enabled flag', () async {
    final fake = _FakeBluetoothLogStore(
      enabled: true,
      logs: const [
        BluetoothLogEntry(
          id: 1,
          timestampMs: 1000,
          direction: 'TX',
          command: 'curve(0x15)',
          dataText: 'bytes=30 payload=...',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [bluetoothLogStoreProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    container.read(bluetoothLogProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    var state = container.read(bluetoothLogProvider);
    expect(state.loading, isFalse);
    expect(state.enabled, isTrue);
    expect(state.logs, hasLength(1));

    await container.read(bluetoothLogProvider.notifier).setEnabled(false);
    state = container.read(bluetoothLogProvider);
    expect(state.enabled, isFalse);
    expect(fake.enabled, isFalse);
  });
}

class _FakeBluetoothLogStore implements BluetoothLogStore {
  _FakeBluetoothLogStore({required this.enabled, required this.logs});

  bool enabled;
  final List<BluetoothLogEntry> logs;

  @override
  Future<void> append({
    required String direction,
    required String command,
    required String dataText,
  }) async {}

  @override
  Future<void> init() async {}

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<List<BluetoothLogEntry>> listAllAsc() async => logs;

  @override
  Future<void> setEnabled(bool enabled) async {
    this.enabled = enabled;
  }
}

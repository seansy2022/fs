import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/provider/bluetooth_provider.dart';
import 'package:rc_ble/rc_ble.dart';

class FakeBluetoothTransport implements BluetoothTransport {
  final StreamController<List<BluetoothScanDevice>> _scanController =
      StreamController.broadcast();
  final StreamController<List<int>> _incomingController =
      StreamController.broadcast();
  final Set<String> connected = <String>{};
  bool started = false;

  @override
  LinkType get type => LinkType.ble;

  @override
  Stream<List<BluetoothScanDevice>> get scanResults => _scanController.stream;

  @override
  Stream<List<int>> get incomingBytes => _incomingController.stream;

  @override
  Future<void> connect(String remoteId) async {
    connected.add(remoteId);
  }

  @override
  Future<void> disconnect(String remoteId) async {
    connected.remove(remoteId);
  }

  void emit(List<BluetoothScanDevice> list) {
    _scanController.add(list);
  }

  @override
  Future<void> startScan() async {
    started = true;
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> send(List<int> bytes) async {}

  Future<void> dispose() async {
    await _scanController.close();
    await _incomingController.close();
  }
}

void main() {
  test('initial bluetooth state is disabled', () {
    final fake = FakeBluetoothTransport();
    final container = ProviderContainer(
      overrides: [bluetoothTransportProvider.overrideWithValue(fake)],
    );
    addTearDown(() async {
      await fake.dispose();
      container.dispose();
    });
    final state = container.read(bluetoothProvider);
    expect(state.isScanning, false);
    expect(state.devices, isEmpty);
  });

  test('startScan enters scanning and receives devices', () async {
    final fake = FakeBluetoothTransport();
    final container = ProviderContainer(
      overrides: [bluetoothTransportProvider.overrideWithValue(fake)],
    );
    addTearDown(() async {
      await fake.dispose();
      container.dispose();
    });

    final notifier = container.read(bluetoothProvider.notifier);
    notifier.startScan();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(bluetoothProvider).isScanning, true);
    expect(fake.started, true);

    fake.emit([
      const BluetoothScanDevice(remoteId: 'A', name: 'MG11-A', rssi: -62),
      const BluetoothScanDevice(remoteId: 'B', name: 'Other', rssi: -81),
    ]);
    await Future<void>.delayed(Duration.zero);
    final state = container.read(bluetoothProvider);
    expect(state.devices.length, 1);
    expect(state.devices.first.name, 'MG11-A');
  });

  test('toggleConnection keeps one connected device', () async {
    final fake = FakeBluetoothTransport();
    final container = ProviderContainer(
      overrides: [bluetoothTransportProvider.overrideWithValue(fake)],
    );
    addTearDown(() async {
      await fake.dispose();
      container.dispose();
    });

    final notifier = container.read(bluetoothProvider.notifier);
    notifier.startScan();
    await Future<void>.delayed(Duration.zero);
    fake.emit([
      const BluetoothScanDevice(remoteId: 'AA:01', name: 'MG11-A', rssi: -58),
      const BluetoothScanDevice(remoteId: 'AA:02', name: 'MG11-B', rssi: -65),
    ]);
    await Future<void>.delayed(Duration.zero);

    final targetId = container.read(bluetoothProvider).devices[1].id;
    notifier.toggleConnection(targetId);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(bluetoothProvider);
    expect(state.isConnected, true);
    expect(state.connectedDeviceMac, 'AA:02');
    expect(state.devices.where((e) => e.connected).length, 1);
  });
}

import 'dart:async';
import 'dart:typed_data';

import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/bluetooth/controllers/device_history_controller.dart';
import 'package:controller_app/src/provider/bluetooth_domain_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bluetooth scan filter only allows R4P devices', () {
    expect(
      shouldIncludeBluetoothDevice(
        const ReceiverScanDevice(
          remoteId: 'r4p-device',
          name: 'R4P Receiver',
          rssi: -48,
        ),
      ),
      isTrue,
    );
    expect(
      shouldIncludeBluetoothDevice(
        const ReceiverScanDevice(
          remoteId: 'other-device',
          name: 'Other Device',
          rssi: -55,
        ),
      ),
      isFalse,
    );
  });

  test(
    'disconnect clears connected display even if info and scan flags linger',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final repository = _FakeReceiverRepository();
      final history = DeviceHistoryController();
      await Future<void>.delayed(Duration.zero);
      await history.rememberDevice(
        const ReceiverScanDevice(
          remoteId: 'last-device',
          name: 'R4P Last Device',
          rssi: -40,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          rememberedDevicesProvider.overrideWith((ref) => history),
        ],
      );
      final subscription = container.listen(
        bluetoothDomainControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(() async {
        subscription.close();
        await Future<void>.delayed(Duration.zero);
        container.dispose();
        await repository.dispose();
      });

      final controller = container.read(
        bluetoothDomainControllerProvider.notifier,
      );

      await controller.startHomeScanSession();
      repository.emitScanResults([
        const ReceiverScanDevice(
          remoteId: 'last-device',
          name: 'R4P Last Device',
          rssi: -40,
        ),
      ]);
      controller.rebuildDeviceViews();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      repository.emitScanResults([
        const ReceiverScanDevice(
          remoteId: 'last-device',
          name: 'R4P Last Device',
          rssi: -42,
          connected: true,
        ),
      ]);
      controller.rebuildDeviceViews();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        container
            .read(bluetoothDomainControllerProvider)
            .connectedDevice
            ?.remoteId,
        'last-device',
      );

      repository.emitDisconnectedWithStaleConnectionMarkers('last-device');
      controller.rebuildDeviceViews();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = container.read(bluetoothDomainControllerProvider);
      expect(state.connectedDevice, isNull);
      expect(state.pairedDevices.first.isConnected, isFalse);
      expect(state.discoveredDevices.first.isConnected, isFalse);
    },
  );

  test(
    'connecting to a different device disconnects current device first',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final repository = _FakeReceiverRepository();
      final history = DeviceHistoryController();
      await Future<void>.delayed(Duration.zero);

      final container = ProviderContainer(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          rememberedDevicesProvider.overrideWith((ref) => history),
        ],
      );
      final subscription = container.listen(
        bluetoothDomainControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(() async {
        subscription.close();
        await Future<void>.delayed(Duration.zero);
        container.dispose();
        await repository.dispose();
      });

      repository.emitScanResults([
        const ReceiverScanDevice(
          remoteId: 'device-a',
          name: 'R4P A',
          rssi: -40,
        ),
        const ReceiverScanDevice(
          remoteId: 'device-b',
          name: 'R4P B',
          rssi: -50,
        ),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final controller = container.read(
        bluetoothDomainControllerProvider.notifier,
      );
      expect(await controller.connect('device-a'), isTrue);
      expect(await controller.connect('device-b'), isTrue);

      expect(repository.connectCalls, <String>['device-a', 'device-b']);
      expect(repository.disconnectCalls, 1);
      expect(
        container
            .read(bluetoothDomainControllerProvider)
            .connectedDevice
            ?.remoteId,
        'device-b',
      );
    },
  );

  test(
    'connect succeeds when repository throws after BLE link is connected',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final repository = _FakeReceiverRepository()
        ..connectThrowsAfterConnectedRemoteId = 'device-a';
      final history = DeviceHistoryController();
      await Future<void>.delayed(Duration.zero);

      final container = ProviderContainer(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          rememberedDevicesProvider.overrideWith((ref) => history),
        ],
      );
      final subscription = container.listen(
        bluetoothDomainControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(() async {
        subscription.close();
        await Future<void>.delayed(Duration.zero);
        container.dispose();
        await repository.dispose();
      });

      repository.emitScanResults([
        const ReceiverScanDevice(
          remoteId: 'device-a',
          name: 'R4P A',
          rssi: -40,
        ),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final controller = container.read(
        bluetoothDomainControllerProvider.notifier,
      );
      final result = await controller.connect('device-a');

      expect(result, isTrue);
      expect(
        container
            .read(bluetoothDomainControllerProvider)
            .connectedDevice
            ?.remoteId,
        'device-a',
      );
      expect(
        container.read(bluetoothDomainControllerProvider).errorMessage,
        isNull,
      );
    },
  );
}

class _FakeReceiverRepository implements ReceiverRepository {
  final List<String> connectCalls = <String>[];
  int disconnectCalls = 0;
  String? connectThrowsAfterConnectedRemoteId;
  final _adapterCtrl = StreamController<AdapterState>.broadcast();
  final _scanCtrl = StreamController<List<ReceiverScanDevice>>.broadcast();
  final _connectionCtrl = StreamController<ReceiverConnectionState>.broadcast();
  final _infoCtrl = StreamController<ReceiverInfo?>.broadcast();
  final _rssiCtrl = StreamController<int?>.broadcast();

  List<ReceiverScanDevice> _scanResults = const <ReceiverScanDevice>[];
  ReceiverConnectionState _connectionState =
      ReceiverConnectionState.disconnected;
  ReceiverInfo? _receiverInfo;

  _FakeReceiverRepository() {
    _adapterCtrl.add(AdapterState.on);
  }

  @override
  Stream<AdapterState> get adapterStateStream async* {
    yield AdapterState.on;
    yield* _adapterCtrl.stream;
  }

  @override
  Stream<int?> get connectedRssiStream async* {
    yield null;
    yield* _rssiCtrl.stream;
  }

  @override
  Stream<ReceiverConnectionState> get connectionStateStream async* {
    yield _connectionState;
    yield* _connectionCtrl.stream;
  }

  @override
  Stream<ReceiverInfo?> get receiverInfoStream async* {
    yield _receiverInfo;
    yield* _infoCtrl.stream;
  }

  @override
  Stream<List<ReceiverScanDevice>> get scanResultsStream async* {
    yield _scanResults;
    yield* _scanCtrl.stream;
  }

  void emitScanResults(List<ReceiverScanDevice> results) {
    _scanResults = results;
    _scanCtrl.add(results);
  }

  void emitConnected(String remoteId) {
    _receiverInfo = ReceiverInfo(
      rfmId: Uint8List.fromList(const [0x01, 0x02, 0x03, 0x04]),
      productModelCode: 0,
      batteryLevel: 88,
      remoteId: remoteId,
    );
    _connectionState = ReceiverConnectionState.connected;
    _connectionCtrl.add(ReceiverConnectionState.connected);
    _infoCtrl.add(_receiverInfo);
  }

  void emitDisconnectedWithStaleConnectionMarkers(String remoteId) {
    _receiverInfo ??= ReceiverInfo(
      rfmId: Uint8List.fromList(const [0x01, 0x02, 0x03, 0x04]),
      productModelCode: 0,
      batteryLevel: 88,
      remoteId: remoteId,
    );
    _connectionState = ReceiverConnectionState.disconnected;
    _connectionCtrl.add(ReceiverConnectionState.disconnected);
    _infoCtrl.add(_receiverInfo);
  }

  @override
  Future<void> startScan() async {}

  @override
  Future<ReceiverInfo> connect(String remoteId) async {
    connectCalls.add(remoteId);
    _scanResults = _scanResults
        .map(
          (device) => device.copyWith(connected: device.remoteId == remoteId),
        )
        .toList(growable: false);
    _scanCtrl.add(_scanResults);
    _connectionState = ReceiverConnectionState.connected;
    _connectionCtrl.add(ReceiverConnectionState.connected);
    if (connectThrowsAfterConnectedRemoteId == remoteId) {
      throw StateError('read receiver info failed');
    }
    _receiverInfo = ReceiverInfo(
      rfmId: Uint8List.fromList(const [0x01, 0x02, 0x03, 0x04]),
      productModelCode: 0,
      batteryLevel: 88,
      remoteId: remoteId,
    );
    _infoCtrl.add(_receiverInfo);
    return _receiverInfo!;
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
    _receiverInfo = null;
    _scanResults = _scanResults
        .map((device) => device.copyWith(connected: false))
        .toList(growable: false);
    _scanCtrl.add(_scanResults);
    _infoCtrl.add(null);
    _connectionState = ReceiverConnectionState.disconnected;
    _connectionCtrl.add(ReceiverConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await _adapterCtrl.close();
    await _scanCtrl.close();
    await _connectionCtrl.close();
    await _infoCtrl.close();
    await _rssiCtrl.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

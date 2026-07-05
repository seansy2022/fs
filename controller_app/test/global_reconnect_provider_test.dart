import 'dart:async';

import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/bluetooth/controllers/device_history_controller.dart';
import 'package:controller_app/src/provider/bluetooth_domain_provider.dart';
import 'package:controller_app/src/provider/global_reconnect_provider.dart';
import 'package:controller_app/src/provider/simulated_bluetooth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'disconnect after connected starts global reconnect until cancel',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final history = DeviceHistoryController();
      await Future<void>.delayed(Duration.zero);
      await history.rememberDevice(
        const ReceiverScanDevice(
          remoteId: 'last-device',
          name: 'R4P Last Device',
          rssi: -40,
        ),
      );
      final connection = StreamController<ReceiverConnectionState>.broadcast();
      final repository = _FakeReceiverRepository();
      late _FakeBluetoothDomainController bluetooth;

      final container = ProviderContainer(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          rememberedDevicesProvider.overrideWith((ref) => history),
          simulatedBluetoothEnabledProvider.overrideWith((ref) => false),
          receiverConnectionProvider.overrideWith((ref) => connection.stream),
          bluetoothDomainControllerProvider.overrideWith((ref) {
            bluetooth = _FakeBluetoothDomainController(ref);
            return bluetooth;
          }),
        ],
      );
      addTearDown(() async {
        await connection.close();
        await repository.dispose();
        container.dispose();
      });

      container.read(globalReconnectControllerProvider);
      connection.add(ReceiverConnectionState.connected);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      connection.add(ReceiverConnectionState.disconnected);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(container.read(globalReconnectControllerProvider).active, isTrue);
      expect(
        container.read(globalReconnectControllerProvider).deviceName,
        'R4P Last Device',
      );
      expect(bluetooth.autoReconnectCalls, 1);

      await container.read(globalReconnectControllerProvider.notifier).cancel();

      expect(container.read(globalReconnectControllerProvider).active, isFalse);
      expect(bluetooth.cancelCalls, 1);
    },
  );

  test(
    'suppressed manual disconnect does not start global reconnect',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final history = DeviceHistoryController();
      await Future<void>.delayed(Duration.zero);
      await history.rememberDevice(
        const ReceiverScanDevice(
          remoteId: 'last-device',
          name: 'R4P Last Device',
          rssi: -40,
        ),
      );
      final connection = StreamController<ReceiverConnectionState>.broadcast();
      final repository = _FakeReceiverRepository();
      late _FakeBluetoothDomainController bluetooth;

      final container = ProviderContainer(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          rememberedDevicesProvider.overrideWith((ref) => history),
          simulatedBluetoothEnabledProvider.overrideWith((ref) => false),
          receiverConnectionProvider.overrideWith((ref) => connection.stream),
          bluetoothDomainControllerProvider.overrideWith((ref) {
            bluetooth = _FakeBluetoothDomainController(ref)
              ..suppressOnce = true;
            return bluetooth;
          }),
        ],
      );
      addTearDown(() async {
        await connection.close();
        await repository.dispose();
        container.dispose();
      });

      container.read(globalReconnectControllerProvider);
      connection.add(ReceiverConnectionState.connected);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      connection.add(ReceiverConnectionState.disconnected);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(container.read(globalReconnectControllerProvider).active, isFalse);
      expect(bluetooth.autoReconnectCalls, 0);
    },
  );
}

class _FakeBluetoothDomainController extends BluetoothDomainController {
  _FakeBluetoothDomainController(super.ref);

  int autoReconnectCalls = 0;
  int cancelCalls = 0;
  bool suppressOnce = false;
  final _autoReconnectCompleter = Completer<bool>();

  @override
  Future<bool> autoReconnectLastDevice({
    Duration timeout = const Duration(seconds: 5),
    bool queueUnavailablePrompt = true,
  }) {
    autoReconnectCalls += 1;
    return _autoReconnectCompleter.future;
  }

  @override
  Future<void> cancelPendingAutoReconnect() async {
    cancelCalls += 1;
    if (!_autoReconnectCompleter.isCompleted) {
      _autoReconnectCompleter.complete(false);
    }
  }

  @override
  bool consumeGlobalReconnectSuppressed() {
    final suppressed = suppressOnce;
    suppressOnce = false;
    return suppressed;
  }
}

class _FakeReceiverRepository implements ReceiverRepository {
  final _adapterCtrl = StreamController<AdapterState>.broadcast();
  final _scanCtrl = StreamController<List<ReceiverScanDevice>>.broadcast();
  final _connectionCtrl = StreamController<ReceiverConnectionState>.broadcast();
  final _infoCtrl = StreamController<ReceiverInfo?>.broadcast();
  final _rssiCtrl = StreamController<int?>.broadcast();

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
    yield ReceiverConnectionState.disconnected;
    yield* _connectionCtrl.stream;
  }

  @override
  Stream<ReceiverInfo?> get receiverInfoStream async* {
    yield null;
    yield* _infoCtrl.stream;
  }

  @override
  Stream<List<ReceiverScanDevice>> get scanResultsStream async* {
    yield const <ReceiverScanDevice>[];
    yield* _scanCtrl.stream;
  }

  @override
  Future<void> stopScan() async {}

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

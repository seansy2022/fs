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

  test('home scan auto-connects the most recently remembered device', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final history = DeviceHistoryController();
    await Future<void>.delayed(Duration.zero);
    await history.rememberDevice(
      const ReceiverScanDevice(
        remoteId: 'last-device',
        name: 'Last Device',
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

    final controller = container.read(bluetoothDomainControllerProvider.notifier);

    await controller.startHomeScanSession();
    repository.emitScanResults([
      const ReceiverScanDevice(
        remoteId: 'other-device',
        name: 'Other Device',
        rssi: -55,
      ),
      const ReceiverScanDevice(
        remoteId: 'last-device',
        name: 'Last Device',
        rssi: -42,
      ),
    ]);
    await Future<void>.delayed(Duration.zero);
    controller.rebuildDeviceViews();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(repository.connectCalls, <String>['last-device']);
    expect(
      container.read(bluetoothDomainControllerProvider).connectedDevice?.remoteId,
      'last-device',
    );
  });
}

class _FakeReceiverRepository implements ReceiverRepository {
  final List<String> connectCalls = <String>[];
  final _adapterCtrl = StreamController<AdapterState>.broadcast();
  final _scanCtrl = StreamController<List<ReceiverScanDevice>>.broadcast();
  final _connectionCtrl =
      StreamController<ReceiverConnectionState>.broadcast();
  final _infoCtrl = StreamController<ReceiverInfo?>.broadcast();
  final _rssiCtrl = StreamController<int?>.broadcast();

  List<ReceiverScanDevice> _scanResults = const <ReceiverScanDevice>[];
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
    yield* _rssiCtrl.stream;
  }

  @override
  Stream<ReceiverConnectionState> get connectionStateStream async* {
    yield* _connectionCtrl.stream;
  }

  @override
  Stream<ReceiverInfo?> get receiverInfoStream async* {
    yield* _infoCtrl.stream;
  }

  @override
  Stream<List<ReceiverScanDevice>> get scanResultsStream async* {
    yield* _scanCtrl.stream;
  }

  void emitScanResults(List<ReceiverScanDevice> results) {
    _scanResults = results;
    _scanCtrl.add(results);
  }

  @override
  Future<void> startScan() async {}

  @override
  Future<ReceiverInfo> connect(String remoteId) async {
    connectCalls.add(remoteId);
    _receiverInfo = ReceiverInfo(
      rfmId: Uint8List.fromList(const [0x01, 0x02, 0x03, 0x04]),
      productModelCode: 0,
      batteryLevel: 88,
      remoteId: remoteId,
    );
    _scanResults = _scanResults
        .map((device) => device.copyWith(connected: device.remoteId == remoteId))
        .toList(growable: false);
    _scanCtrl.add(_scanResults);
    _connectionCtrl.add(ReceiverConnectionState.connected);
    _infoCtrl.add(_receiverInfo);
    return _receiverInfo!;
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

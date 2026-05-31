import 'package:controller_app/src/app/app_routes.dart';
import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/home/view/home_page.dart';
import 'package:controller_app/src/provider/bluetooth_domain_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

void main() {
  testWidgets('start button navigates to control page when disconnected', (
    tester,
  ) async {
    final repository = _FakeReceiverRepository(
      connectionState: ReceiverConnectionState.disconnected,
    );
    late _FakeBluetoothDomainController bluetoothController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          bluetoothDomainControllerProvider.overrideWith((ref) {
            bluetoothController = _FakeBluetoothDomainController(ref);
            return bluetoothController;
          }),
        ],
        child: MaterialApp(
          home: const HomePage(),
          routes: {
            AppRoutes.control: (_) =>
                const Scaffold(body: Text('control-page')),
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('开始'));
    await tester.pumpAndSettle();

    expect(find.text('control-page'), findsOneWidget);
    expect(bluetoothController.ensureScanStoppedCalls, 1);
  });

  testWidgets('start button navigates to control page when connected', (
    tester,
  ) async {
    final repository = _FakeReceiverRepository(
      connectionState: ReceiverConnectionState.connected,
    );
    late _FakeBluetoothDomainController bluetoothController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          bluetoothDomainControllerProvider.overrideWith((ref) {
            bluetoothController = _FakeBluetoothDomainController(ref);
            return bluetoothController;
          }),
        ],
        child: MaterialApp(
          home: const HomePage(),
          routes: {
            AppRoutes.control: (_) =>
                const Scaffold(body: Text('control-page')),
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('开始'));
    await tester.pumpAndSettle();

    expect(find.text('control-page'), findsOneWidget);
    expect(bluetoothController.ensureScanStoppedCalls, 1);
  });
}

class _FakeBluetoothDomainController extends BluetoothDomainController {
  _FakeBluetoothDomainController(Ref ref) : super(ref);

  int ensureScanStoppedCalls = 0;

  @override
  Future<void> bootstrapHomeBluetooth() async {}

  @override
  Future<void> ensureScanStopped() async {
    ensureScanStoppedCalls += 1;
  }

  @override
  void dispose() {}
}

class _FakeReceiverRepository implements ReceiverRepository {
  _FakeReceiverRepository({required ReceiverConnectionState connectionState})
    : _connectionState = connectionState;

  final ReceiverConnectionState _connectionState;

  @override
  ReceiverConnectionState get connectionState => _connectionState;

  @override
  ReceiverInfo? get receiverInfo => null;

  @override
  Stream<ReceiverInfo?> get receiverInfoStream => Stream.value(null);

  @override
  Stream<ReceiverConnectionState> get connectionStateStream =>
      Stream.value(_connectionState);

  @override
  Stream<int?> get connectedRssiStream => Stream.value(null);

  @override
  Stream<List<ReceiverScanDevice>> get scanResultsStream =>
      Stream.value(const <ReceiverScanDevice>[]);

  @override
  Stream<AdapterState> get adapterStateStream => Stream.value(AdapterState.on);

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

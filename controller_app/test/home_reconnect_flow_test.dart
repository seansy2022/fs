import 'dart:async';

import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/bluetooth/controllers/device_history_controller.dart';
import 'package:controller_app/src/features/home/view/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home page scans remembered device and prompts when missing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FakeReceiverRepository();
    final history = DeviceHistoryController();
    addTearDown(repository.dispose);
    await Future<void>.delayed(Duration.zero);
    await history.rememberDevice(
      const ReceiverScanDevice(
        remoteId: 'last-device',
        name: 'R4P Last Device',
        rssi: -40,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          rememberedDevicesProvider.overrideWith((ref) => history),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('扫描上次设备中...'), findsOneWidget);
    expect(repository.scanAndConnectCalls, 1);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('R4P Last Device设备连接失败'), findsOneWidget);
  });
}

class _FakeReceiverRepository implements ReceiverRepository {
  int scanAndConnectCalls = 0;
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
  Future<ReceiverInfo> scanAndConnectByBlueId(
    String blueId, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    scanAndConnectCalls += 1;
    await Future<void>.delayed(timeout);
    throw TimeoutException('Unable to find bluetooth device: $blueId');
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

import 'dart:async';
import 'dart:typed_data';

import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/provider/bluetooth_domain_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('仓库已连接时不受 Riverpod 异步状态滞后影响', () async {
    final repository = _ConnectedRepositoryWithStaleStreams();
    final container = ProviderContainer(
      overrides: [receiverRepositoryProvider.overrideWith((ref) => repository)],
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

    final connected = await container
        .read(bluetoothDomainControllerProvider.notifier)
        .connect('last-device');

    expect(connected, isTrue);
    expect(repository.connectCalls, 0);
  });
}

class _ConnectedRepositoryWithStaleStreams implements ReceiverRepository {
  final _adapter = StreamController<AdapterState>.broadcast();
  final _connection = StreamController<ReceiverConnectionState>.broadcast();
  final _info = StreamController<ReceiverInfo?>.broadcast();
  final _rssi = StreamController<int?>.broadcast();
  final _scan = StreamController<List<ReceiverScanDevice>>.broadcast();

  int connectCalls = 0;

  @override
  ReceiverConnectionState get connectionState =>
      ReceiverConnectionState.connected;

  @override
  ReceiverInfo get receiverInfo => ReceiverInfo(
    rfmId: Uint8List.fromList(const [1, 2, 3, 4]),
    productModelCode: 1,
    batteryLevel: 80,
    remoteId: 'last-device',
  );

  @override
  Stream<AdapterState> get adapterStateStream async* {
    yield AdapterState.on;
    yield* _adapter.stream;
  }

  @override
  Stream<ReceiverConnectionState> get connectionStateStream async* {
    yield ReceiverConnectionState.disconnected;
    yield* _connection.stream;
  }

  @override
  Stream<ReceiverInfo?> get receiverInfoStream async* {
    yield null;
    yield* _info.stream;
  }

  @override
  Stream<int?> get connectedRssiStream async* {
    yield null;
    yield* _rssi.stream;
  }

  @override
  Stream<List<ReceiverScanDevice>> get scanResultsStream async* {
    yield const [];
    yield* _scan.stream;
  }

  @override
  Future<ReceiverInfo> connect(String remoteId) async {
    connectCalls++;
    return receiverInfo;
  }

  @override
  Future<void> stopScan() async {}

  /// 关闭测试流，避免测试结束后残留异步资源。
  @override
  Future<void> dispose() async {
    await _adapter.close();
    await _connection.close();
    await _info.close();
    await _rssi.close();
    await _scan.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

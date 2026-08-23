import 'dart:async';
import 'dart:typed_data';

import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/features/settings/models/failsafe_value_rules.dart';
import 'package:controller_app/src/features/settings/view/failsafe_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('failsafe percentage conversion uses a 1500us center', () {
    expect(failsafeUsToPercent(900), -120);
    expect(failsafeUsToPercent(1500), 0);
    expect(failsafeUsToPercent(2100), 120);
    expect(failsafePercentToUs(-120), 900);
    expect(failsafePercentToUs(0), 1500);
    expect(failsafePercentToUs(120), 2100);
  });

  testWidgets('fixed failsafe value uses percentage input dialog', (
    tester,
  ) async {
    final repository = _FakeReceiverRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: const MaterialApp(home: FailsafePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.text('0%').first,
        matching: find.byType(ItemButton),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('0%').first);
    await tester.pumpAndSettle();

    // 弹窗标题也会显示“固定值”，这里只验证四个通道标签仍存在。
    expect(find.text('固定值'), findsAtLeastNWidgets(4));
    expect(
      find.byKey(const ValueKey('numeric-input-dialog-padding')),
      findsOne,
    );
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '-120');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('-120%'), findsOneWidget);
    expect(repository.writtenConfigs.last.throttleUs, 1500);
    expect(repository.writtenConfigs.last.steeringUs, 900);
  });

  testWidgets('toggling failsafe hold writes bluetooth config', (tester) async {
    final repository = _FakeReceiverRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: const MaterialApp(home: FailsafePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('固定值').first);
    await tester.pumpAndSettle();

    expect(repository.writtenConfigs.last.throttleUs, 1500);
    expect(repository.writtenConfigs.last.steeringUs, 1500);
    expect(repository.writtenConfigs.last.steeringHold, isTrue);
    expect(repository.readFailsafeCount, 1);
    expect(
      repository.writtenConfigs.last.ch5ToCh10Raw,
      List<int>.filled(6, 1500),
    );
  });

  testWidgets('failsafe read retries once after a timeout', (tester) async {
    final repository = _FakeReceiverRepository(failFailsafeReads: 1);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: const MaterialApp(home: FailsafePage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(repository.readFailsafeCount, 2);
  });

  testWidgets('reads failsafe after the page is opened before connection', (
    tester,
  ) async {
    final repository = _FakeReceiverRepository(
      initialConnectionState: ReceiverConnectionState.disconnected,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: const MaterialApp(home: FailsafePage()),
      ),
    );
    await tester.pump();
    expect(repository.readFailsafeCount, 0);

    repository.emitConnectionState(ReceiverConnectionState.connected);
    await tester.pumpAndSettle();

    expect(repository.readFailsafeCount, 1);
  });

  testWidgets('disabled CH3 is fixed at 1500 and cannot be edited', (
    tester,
  ) async {
    final repository = _FakeReceiverRepository();
    final settingsController = SettingsController();
    final ch3 = settingsController.state.channels[2];
    settingsController.updateChannel(
      2,
      ch3.copyWith(controlType: AuxControlType.disabled),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          appSettingsProvider.overrideWith((ref) => settingsController),
        ],
        child: const MaterialApp(home: FailsafePage()),
      ),
    );
    await tester.pumpAndSettle();

    final valueButton = tester.widget<ItemButton>(
      find.byKey(const ValueKey<String>('failsafe-CH3-value')),
    );
    final disabledButton = tester.widget<ItemButton>(
      find.byKey(const ValueKey<String>('failsafe-CH3-mode')),
    );

    expect(valueButton.onTap, isNull);
    expect(disabledButton.onTap, isNull);
    expect(repository.writtenConfigs, isEmpty);
  });
}

class _FakeReceiverRepository implements ReceiverRepository {
  _FakeReceiverRepository({
    this.failFailsafeReads = 0,
    ReceiverConnectionState initialConnectionState =
        ReceiverConnectionState.connected,
  }) : _connectionState = initialConnectionState;

  final List<ReceiverFailsafeConfig> writtenConfigs =
      <ReceiverFailsafeConfig>[];
  final StreamController<ReceiverConnectionState> _connectionCtrl =
      StreamController<ReceiverConnectionState>.broadcast();
  final ReceiverInfo _receiverInfo = ReceiverInfo(
    rfmId: Uint8List.fromList(const [0x01, 0x02, 0x03, 0x04]),
    productModelCode: 0,
    batteryLevel: 90,
    remoteId: 'test-device',
  );
  int readFailsafeCount = 0;
  int failFailsafeReads;
  ReceiverConnectionState _connectionState;

  @override
  ReceiverInfo get receiverInfo => _receiverInfo;

  @override
  ReceiverConnectionState get connectionState => _connectionState;

  @override
  Stream<ReceiverConnectionState> get connectionStateStream async* {
    yield connectionState;
    yield* _connectionCtrl.stream;
  }

  /// 模拟蓝牙连接状态变化。
  void emitConnectionState(ReceiverConnectionState state) {
    _connectionState = state;
    _connectionCtrl.add(state);
  }

  @override
  Future<ReceiverFailsafeConfig> readFailsafe() async {
    readFailsafeCount++;
    if (failFailsafeReads > 0) {
      failFailsafeReads--;
      throw TimeoutException('read failsafe timeout');
    }
    return const ReceiverFailsafeConfig(
      throttleUs: 1500,
      steeringUs: 1500,
      ch5ToCh10Raw: [1500, 1500, 1500, 1500, 1500, 1500],
    );
  }

  @override
  Future<ReceiverInfo> readReceiverInfo() async {
    return _receiverInfo;
  }

  @override
  Future<ReceiverFailsafeConfig> writeFailsafe(
    ReceiverFailsafeConfig config,
  ) async {
    writtenConfigs.add(config);
    return config;
  }

  @override
  Future<void> dispose() async {
    await _connectionCtrl.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

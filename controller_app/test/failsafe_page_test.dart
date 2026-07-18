import 'dart:typed_data';

import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/features/settings/view/failsafe_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fixed failsafe value uses numeric input dialog', (tester) async {
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
        of: find.text('1500').first,
        matching: find.byType(ItemButton),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('1500').first);
    await tester.pumpAndSettle();

    expect(find.text('固定值'), findsNWidgets(4));
    expect(
      find.byKey(const ValueKey('numeric-input-dialog-padding')),
      findsOne,
    );
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '800');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('900'), findsOneWidget);
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
  final List<ReceiverFailsafeConfig> writtenConfigs =
      <ReceiverFailsafeConfig>[];
  final ReceiverInfo _receiverInfo = ReceiverInfo(
    rfmId: Uint8List.fromList(const [0x01, 0x02, 0x03, 0x04]),
    productModelCode: 0,
    batteryLevel: 90,
    remoteId: 'test-device',
  );

  @override
  ReceiverInfo get receiverInfo => _receiverInfo;

  @override
  Future<ReceiverFailsafeConfig> readFailsafe() async {
    return const ReceiverFailsafeConfig(throttleUs: 1500, steeringUs: 1500);
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
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

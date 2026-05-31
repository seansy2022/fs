import 'dart:typed_data';

import 'package:controller_app/src/core/providers.dart';
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

    expect(find.text('固定值'), findsNWidgets(3));
    expect(
      find.byKey(const ValueKey('numeric-input-dialog-padding')),
      findsOne,
    );
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '2200');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('2000'), findsOneWidget);
    expect(repository.writtenConfigs.last.throttleUs, 1500);
    expect(repository.writtenConfigs.last.steeringUs, 2000);
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
    expect(repository.writtenConfigs.last.steeringUs, 0);
  });
}

class _FakeReceiverRepository implements ReceiverRepository {
  final List<ReceiverFailsafeConfig> writtenConfigs = <ReceiverFailsafeConfig>[];
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

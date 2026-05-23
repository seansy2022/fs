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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith(
            (ref) => _FakeReceiverRepository(),
          ),
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
  });
}

class _FakeReceiverRepository implements ReceiverRepository {
  @override
  Future<ReceiverFailsafeConfig> readFailsafe() async {
    return const ReceiverFailsafeConfig(throttleUs: 1500, steeringUs: 1500);
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

import 'package:controller_app/src/core/localization/app_localizations.dart';
import 'package:controller_app/src/features/bluetooth/widgets/receiver_safety_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AppText.setLanguage(AppLanguage.chinese);
  });

  testWidgets('连接其他接收机时显示统一安全确认弹窗', (tester) async {
    bool? result;
    await _pumpSwitchEntry(
      tester,
      connectedRemoteId: 'device-a',
      targetRemoteId: 'device-b',
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('连接'));
    await tester.pumpAndSettle();

    expect(find.text('操作会导致失控，请确认安全！\n确定断开当前设备，连接新设备吗？'), findsOneWidget);
    final warningIcon = find.byKey(
      const ValueKey<String>('receiver-safety-warning-icon'),
    );
    expect(warningIcon, findsOneWidget);
    expect(tester.getSize(warningIcon), const Size.square(40));
    expect(result, isNull);

    await tester.tap(find.text('否'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('确认切换接收机后允许继续连接', (tester) async {
    bool? result;
    await _pumpSwitchEntry(
      tester,
      connectedRemoteId: 'device-a',
      targetRemoteId: 'device-b',
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('连接'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('是'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('无连接或点击当前接收机时无需弹窗', (tester) async {
    for (final connectedRemoteId in <String?>[null, 'device-b']) {
      bool? result;
      await _pumpSwitchEntry(
        tester,
        connectedRemoteId: connectedRemoteId,
        targetRemoteId: 'device-b',
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('连接'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(Dialog), findsNothing);
    }
  });
}

/// 构建切换接收机入口，验证弹窗结果是否放行后续连接流程。
Future<void> _pumpSwitchEntry(
  WidgetTester tester, {
  required String? connectedRemoteId,
  required String targetRemoteId,
  required ValueChanged<bool> onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final result = await confirmReceiverSwitchIfNeeded(
                context,
                connectedRemoteId: connectedRemoteId,
                targetRemoteId: targetRemoteId,
              );
              onResult(result);
            },
            child: const Text('连接'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

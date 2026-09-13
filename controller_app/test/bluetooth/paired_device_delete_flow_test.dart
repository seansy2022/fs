import 'package:controller_app/src/core/localization/app_localizations.dart';
import 'package:controller_app/src/features/bluetooth/widgets/paired_device_delete_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  setUp(() {
    AppText.setLanguage(AppLanguage.chinese);
  });

  testWidgets('未连接设备点击删除后直接移除', (tester) async {
    var disconnectCalls = 0;
    var removeCalls = 0;

    await _pumpDeleteEntry(
      tester,
      isConnected: false,
      disconnect: () async {
        disconnectCalls += 1;
        return true;
      },
      remove: () async => removeCalls += 1,
    );
    await tester.tap(find.byKey(const ValueKey<String>('delete-device')));
    await tester.pumpAndSettle();

    expect(find.text('操作会导致失控，请确认安全！\n此设备正在使用，确定删除吗？'), findsNothing);
    expect(disconnectCalls, 0);
    expect(removeCalls, 1);
  });

  testWidgets('未连接设备直接删除失败时显示提示', (tester) async {
    await _pumpDeleteEntry(
      tester,
      isConnected: false,
      disconnect: () async => true,
      remove: () async => throw StateError('remove failed'),
    );
    await tester.tap(find.byKey(const ValueKey<String>('delete-device')));
    await tester.pumpAndSettle();

    expect(find.text('删除历史设备失败，请重试。'), findsOneWidget);
  });

  testWidgets('已连接设备选择否则不执行删除', (tester) async {
    var disconnectCalls = 0;
    var removeCalls = 0;

    await _pumpDeleteEntry(
      tester,
      isConnected: true,
      disconnect: () async {
        disconnectCalls += 1;
        return true;
      },
      remove: () async => removeCalls += 1,
    );
    await tester.tap(find.byKey(const ValueKey<String>('delete-device')));
    await tester.pumpAndSettle();

    expect(find.text('操作会导致失控，请确认安全！\n此设备正在使用，确定删除吗？'), findsOneWidget);
    final warningIcon = find.byKey(
      const ValueKey<String>('receiver-safety-warning-icon'),
    );
    expect(warningIcon, findsOneWidget);
    expect(tester.getSize(warningIcon), const Size.square(40));
    await tester.tap(find.text('否'));
    await tester.pumpAndSettle();

    expect(disconnectCalls, 0);
    expect(removeCalls, 0);
  });

  testWidgets('已连接设备选择是后先断开再删除', (tester) async {
    final events = <String>[];

    await _pumpDeleteEntry(
      tester,
      isConnected: true,
      disconnect: () async {
        events.add('disconnect');
        return true;
      },
      remove: () async => events.add('remove'),
    );
    await tester.tap(find.byKey(const ValueKey<String>('delete-device')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('是'));
    await tester.pumpAndSettle();

    expect(events, <String>['disconnect', 'remove']);
  });

  testWidgets('已连接设备断开失败时不删除记录', (tester) async {
    var removeCalls = 0;

    await _pumpDeleteEntry(
      tester,
      isConnected: true,
      disconnect: () async => false,
      remove: () async => removeCalls += 1,
    );
    await tester.tap(find.byKey(const ValueKey<String>('delete-device')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('是'));
    await tester.pumpAndSettle();

    expect(removeCalls, 0);
    expect(find.text('当前连接接收机断开失败，请重试。'), findsOneWidget);
  });
}

/// 构建统一删除入口，注入断开和删除回调以验证业务调用顺序。
Future<void> _pumpDeleteEntry(
  WidgetTester tester, {
  required bool isConnected,
  required Future<bool> Function() disconnect,
  required Future<void> Function() remove,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const ValueKey<String>('delete-device'),
            onPressed: () async {
              await deletePairedDeviceWithFeedback(
                context,
                isConnected: isConnected,
                disconnect: disconnect,
                remove: remove,
              );
            },
            child: const Text('删除'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

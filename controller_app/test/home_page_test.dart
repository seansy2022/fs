import 'package:controller_app/src/app/app_routes.dart';
import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/home/view/home_page.dart';
import 'package:controller_app/src/provider/bluetooth_domain_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import 'fakes/home_page_fakes.dart';

void main() {
  testWidgets('start button navigates to control page when disconnected', (
    tester,
  ) async {
    final repository = FakeHomeReceiverRepository(
      connectionState: ReceiverConnectionState.disconnected,
    );
    late FakeHomeBluetoothDomainController bluetoothController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          bluetoothDomainControllerProvider.overrideWith((ref) {
            bluetoothController = FakeHomeBluetoothDomainController(ref);
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
    final repository = FakeHomeReceiverRepository(
      connectionState: ReceiverConnectionState.connected,
    );
    late FakeHomeBluetoothDomainController bluetoothController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          bluetoothDomainControllerProvider.overrideWith((ref) {
            bluetoothController = FakeHomeBluetoothDomainController(ref);
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

  testWidgets('connected scan pairing asks for confirmation first', (
    tester,
  ) async {
    final repository = FakeHomeReceiverRepository(
      connectionState: ReceiverConnectionState.connected,
    );
    late FakeHomeBluetoothDomainController bluetoothController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          bluetoothDomainControllerProvider.overrideWith((ref) {
            bluetoothController = FakeHomeBluetoothDomainController(ref);
            return bluetoothController;
          }),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(RCButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('去配对'));
    await tester.pumpAndSettle();

    expect(find.text('确定放弃当前连接接收机去配对其它接收机？'), findsOneWidget);
    expect(bluetoothController.disconnectCalls, 0);
    expect(bluetoothController.startListScanSessionCalls, 0);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(bluetoothController.disconnectCalls, 0);
    expect(bluetoothController.startListScanSessionCalls, 0);
  });

  testWidgets('confirmed scan pairing disconnects before opening scan', (
    tester,
  ) async {
    final repository = FakeHomeReceiverRepository(
      connectionState: ReceiverConnectionState.connected,
    );
    late FakeHomeBluetoothDomainController bluetoothController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiverRepositoryProvider.overrideWith((ref) => repository),
          bluetoothDomainControllerProvider.overrideWith((ref) {
            bluetoothController = FakeHomeBluetoothDomainController(ref);
            return bluetoothController;
          }),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(RCButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('去配对'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(bluetoothController.disconnectCalls, 1);
    expect(bluetoothController.startListScanSessionCalls, 1);
    expect(find.text('去配对'), findsOneWidget);
  });
}

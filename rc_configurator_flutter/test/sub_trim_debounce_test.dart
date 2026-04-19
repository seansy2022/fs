import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_provider.dart';
import 'package:rc_configurator_flutter/src/types.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  test('sub trim updates are sent after 500ms debounce', () async {
    final transport = MemoryLinkTransport();
    final container = ProviderContainer(
      overrides: [linkTransportProvider.overrideWithValue(transport)],
    );
    addTearDown(() async {
      await transport.dispose();
      container.dispose();
    });
    final notifier = container.read(rcAppStateProvider.notifier);
    await _connect(notifier, container, transport, 'B-3');
    transport.sentPackets.clear();

    final first = container.read(rcAppStateProvider).channels.first;
    notifier.dispatch(
      SubTrimUpdatedIntent(id: first.id, next: first.copyWith(offset: 2)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(transport.sentPackets, isEmpty);

    final latest = container.read(rcAppStateProvider).channels.first;
    notifier.dispatch(
      SubTrimUpdatedIntent(id: latest.id, next: latest.copyWith(offset: 4)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(transport.sentPackets, isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 260));
    expect(transport.sentPackets, isNotEmpty);
  });

  test('curve updates are sent after 500ms debounce', () async {
    final transport = MemoryLinkTransport();
    final container = ProviderContainer(
      overrides: [linkTransportProvider.overrideWithValue(transport)],
    );
    addTearDown(() async {
      await transport.dispose();
      container.dispose();
    });
    final notifier = container.read(rcAppStateProvider.notifier);
    await _connect(notifier, container, transport, 'B-4');
    transport.sentPackets.clear();

    notifier.dispatch(const CurveValueUpdatedIntent(10));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(transport.sentPackets, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    expect(transport.sentPackets, isNotEmpty);
  });

  test('mixing updates are sent after 400ms debounce', () async {
    final transport = MemoryLinkTransport();
    final container = ProviderContainer(
      overrides: [linkTransportProvider.overrideWithValue(transport)],
    );
    addTearDown(() async {
      await transport.dispose();
      container.dispose();
    });
    final notifier = container.read(rcAppStateProvider.notifier);
    await _connect(notifier, container, transport, 'B-5');
    transport.sentPackets.clear();

    notifier.dispatch(
      const MixingSettingsUpdatedIntent(
        MixingSettings(
          activeMode: '4WS',
          enabled: false,
          ratio: 88,
          curve: 0,
          direction: '',
          selectedChannel: 'CH3',
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(transport.sentPackets, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    expect(transport.sentPackets, isNotEmpty);
  });
}

Future<void> _connect(
  RcAppController notifier,
  ProviderContainer container,
  MemoryLinkTransport transport,
  String remoteId,
) async {
  notifier.startScan();
  await Future<void>.delayed(Duration.zero);
  transport.emitScanResults([
    BluetoothScanDevice(remoteId: remoteId, name: 'MG11 Debounce', rssi: -48),
  ]);
  await Future<void>.delayed(Duration.zero);
  final deviceId = container
      .read(rcAppStateProvider)
      .bluetooth
      .devices
      .first
      .id;
  notifier.toggleConnection(deviceId);
  await Future<void>.delayed(const Duration(milliseconds: 30));
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/lib/protocol/protocol_adapter_v1.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_provider.dart';
import 'package:rc_ble/rc_ble.dart';

class TestEnv {
  const TestEnv({
    required this.container,
    required this.transport,
    required this.notifier,
  });
  final ProviderContainer container;
  final MemoryLinkTransport transport;
  final RcAppController notifier;
}

Future<TestEnv> connectTestEnv() async {
  final transport = _AckMemoryLinkTransport();
  final container = ProviderContainer(
    overrides: [
      linkTransportProvider.overrideWithValue(transport),
      protocolAdapterProvider.overrideWithValue(_NoStartupProtocolAdapter()),
    ],
  );
  final notifier = container.read(rcAppStateProvider.notifier);
  notifier.startScan();
  await Future<void>.delayed(Duration.zero);
  transport.emitScanResults([
    const BluetoothScanDevice(remoteId: 'B-8', name: 'MG11 Test', rssi: -44),
  ]);
  await Future<void>.delayed(Duration.zero);
  final id = container.read(rcAppStateProvider).bluetooth.devices.first.id;
  notifier.toggleConnection(id);
  await Future<void>.delayed(const Duration(milliseconds: 30));
  transport.sentPackets.clear();
  return TestEnv(
    container: container,
    transport: transport,
    notifier: notifier,
  );
}

Future<void> disposeTestEnv(TestEnv env) async {
  await env.transport.dispose();
  env.container.dispose();
}

Future<void> expectSentCommands(
  TestEnv env,
  void Function() action,
  List<BluetoothCommand> expected, {
  required bool debounced,
}) async {
  env.transport.sentPackets.clear();
  action();
  await Future<void>.delayed(Duration(milliseconds: debounced ? 560 : 80));
  expect(sentCommands(env.transport), expected);
}

List<BluetoothCommand> sentCommands(MemoryLinkTransport transport) {
  final out = <BluetoothCommand>[];
  for (final packet in transport.sentPackets) {
    final frame = BluetoothFrame.tryParse(packet);
    final cmd = frame == null ? null : BluetoothCommand.fromId(frame.command);
    if (cmd != null) out.add(cmd);
  }
  return out;
}

class _NoStartupProtocolAdapter extends ProtocolAdapterV1 {
  @override
  Iterable<BluetoothCommand> startupReadCommands() =>
      const <BluetoothCommand>[];
}

class _AckMemoryLinkTransport extends MemoryLinkTransport {
  @override
  Future<void> send(List<int> bytes) async {
    await super.send(bytes);
    final frame = BluetoothFrame.tryParse(bytes);
    if (frame == null || frame.length == 0) return;
    emitIncoming(
      BluetoothFrame(
        seq: frame.seq,
        command: frame.command,
        length: 1,
        data: const [0x20],
      ).toBytes(),
    );
  }
}

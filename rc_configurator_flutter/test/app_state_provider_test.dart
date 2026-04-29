import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/lib/protocol/protocol_adapter_v1.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_provider.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/control_mapping_options.dart';
import 'package:rc_configurator_flutter/src/types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('model names are restored from local preferences on startup', () async {
    SharedPreferences.setMockInitialValues({
      'rc_model_names': <String>['MOD01-A', 'MOD02-B'],
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(rcAppStateProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final models = container.read(rcAppStateProvider).models;
    expect(models[0].name, 'MOD01-A');
    expect(models[1].name, 'MOD02-B');
  });

  test('model rename is persisted to local preferences', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);

    notifier.dispatch(const ModelRenamedIntent(id: 'MOD02', name: '赛车模型'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList('rc_model_names');
    expect(names, isNotNull);
    expect(names![1], '赛车模型');
  });

  test('app state reflects injected usb transport device type', () async {
    final transport = MemoryLinkTransport(linkType: LinkType.usb);
    final container = ProviderContainer(
      overrides: [linkTransportProvider.overrideWithValue(transport)],
    );
    addTearDown(() async {
      await transport.dispose();
      container.dispose();
    });

    final notifier = container.read(rcAppStateProvider.notifier);
    notifier.startScan();
    await Future<void>.delayed(Duration.zero);
    transport.emitScanResults([
      const BluetoothScanDevice(remoteId: 'U-1', name: 'USB Device', rssi: -45),
    ]);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(rcAppStateProvider);
    expect(state.bluetooth.devices, hasLength(1));
    expect(state.bluetooth.devices.first.type, 'usb');
  });

  test(
    'connected device stays visible and scanning flag stays false',
    () async {
      final transport = _DelayedConnectMemoryLinkTransport();
      final container = ProviderContainer(
        overrides: [linkTransportProvider.overrideWithValue(transport)],
      );
      addTearDown(() async {
        await transport.dispose();
        container.dispose();
      });

      final notifier = container.read(rcAppStateProvider.notifier);
      notifier.startScan();
      await Future<void>.delayed(Duration.zero);
      transport.emitScanResults([
        const BluetoothScanDevice(
          remoteId: 'B-9',
          name: 'MG11 Persist',
          rssi: -52,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      final deviceId = container
          .read(rcAppStateProvider)
          .bluetooth
          .devices
          .first
          .id;
      notifier.toggleConnection(deviceId);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      transport.emitScanResults(const <BluetoothScanDevice>[]);
      await Future<void>.delayed(const Duration(milliseconds: 90));
      transport.emitScanResults(const <BluetoothScanDevice>[]);
      await Future<void>.delayed(Duration.zero);

      final bluetooth = container.read(rcAppStateProvider).bluetooth;
      expect(bluetooth.isConnected, isTrue);
      expect(bluetooth.isScanning, isFalse);
      expect(
        bluetooth.devices.any(
          (d) => d.mac == 'B-9' && d.name == 'MG11 Persist' && d.connected,
        ),
        isTrue,
      );
    },
  );

  test(
    'intents are synced through abstract transport after connection',
    () async {
      final transport = MemoryLinkTransport();
      final container = ProviderContainer(
        overrides: [linkTransportProvider.overrideWithValue(transport)],
      );
      addTearDown(() async {
        await transport.dispose();
        container.dispose();
      });

      final notifier = container.read(rcAppStateProvider.notifier);
      notifier.startScan();
      await Future<void>.delayed(Duration.zero);
      transport.emitScanResults([
        const BluetoothScanDevice(
          remoteId: 'B-1',
          name: 'MG11 Device',
          rssi: -50,
        ),
        const BluetoothScanDevice(remoteId: 'B-X', name: 'Other', rssi: -60),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(rcAppStateProvider).bluetooth.devices,
        hasLength(1),
      );
      final deviceId = container
          .read(rcAppStateProvider)
          .bluetooth
          .devices
          .first
          .id;
      notifier.toggleConnection(deviceId);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      notifier.dispatch(const CurveValueUpdatedIntent(12));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(transport.sentPackets, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 260));
      expect(transport.sentPackets, isNotEmpty);
    },
  );

  test('refreshForScreen triggers page-specific read command', () async {
    final transport = MemoryLinkTransport();
    final container = ProviderContainer(
      overrides: [
        linkTransportProvider.overrideWithValue(transport),
        protocolAdapterProvider.overrideWithValue(_NoStartupProtocolAdapter()),
      ],
    );
    addTearDown(() async {
      await transport.dispose();
      container.dispose();
    });

    final notifier = container.read(rcAppStateProvider.notifier);
    notifier.startScan();
    await Future<void>.delayed(Duration.zero);
    transport.emitScanResults([
      const BluetoothScanDevice(remoteId: 'B-2', name: 'MG11 Test', rssi: -44),
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
    transport.sentPackets.clear();

    notifier.refreshForScreen(Screen.reverse);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(transport.sentPackets.length, 1);
    final sent = BluetoothFrame.tryParse(transport.sentPackets.first);
    expect(sent, isNotNull);
    expect(sent!.command, BluetoothCommand.channelReverse.id);
    expect(sent.length, 0);
  });

  test('refreshForScreen de-duplicates same screen within 200ms', () async {
    final transport = _RefreshAckingMemoryLinkTransport();
    final container = ProviderContainer(
      overrides: [
        linkTransportProvider.overrideWithValue(transport),
        protocolAdapterProvider.overrideWithValue(_NoStartupProtocolAdapter()),
      ],
    );
    addTearDown(() async {
      await transport.dispose();
      container.dispose();
    });

    final notifier = container.read(rcAppStateProvider.notifier);
    notifier.startScan();
    await Future<void>.delayed(Duration.zero);
    transport.emitScanResults([
      const BluetoothScanDevice(remoteId: 'B-3', name: 'MG11 Test', rssi: -44),
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
    transport.sentPackets.clear();

    final first = await notifier.refreshForScreen(Screen.reverse);
    expect(first, isTrue);
    final firstCount = _sentReadCount(
      transport,
      BluetoothCommand.channelReverse,
    );
    expect(firstCount, 1);

    final second = await notifier.refreshForScreen(Screen.reverse);
    expect(second, isTrue);
    final secondCount = _sentReadCount(
      transport,
      BluetoothCommand.channelReverse,
    );
    expect(secondCount, 1);

    await Future<void>.delayed(const Duration(milliseconds: 220));
    final third = await notifier.refreshForScreen(Screen.reverse);
    expect(third, isTrue);
    final thirdCount = _sentReadCount(
      transport,
      BluetoothCommand.channelReverse,
    );
    expect(thirdCount, 2);
  });

  test('control mapping refresh defaults to CH11 after sync', () async {
    final transport = _RefreshAckingMemoryLinkTransport();
    final container = ProviderContainer(
      overrides: [
        linkTransportProvider.overrideWithValue(transport),
        protocolAdapterProvider.overrideWithValue(_NoStartupProtocolAdapter()),
      ],
    );
    addTearDown(() async {
      await transport.dispose();
      container.dispose();
    });

    final notifier = container.read(rcAppStateProvider.notifier);
    notifier.startScan();
    await Future<void>.delayed(Duration.zero);
    transport.emitScanResults([
      const BluetoothScanDevice(remoteId: 'B-4', name: 'MG11 Test', rssi: -44),
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
    notifier.state = container
        .read(rcAppStateProvider)
        .copyWith(
          controlMapping: container
              .read(rcAppStateProvider)
              .controlMapping
              .copyWith(channel: 'CH3'),
        );
    notifier.enterControlMappingPage();
    transport.sentPackets.clear();

    final success = await notifier.refreshForScreen(Screen.controlMapping);
    expect(success, isTrue);

    final indexes = transport.sentPackets
        .map(BluetoothFrame.tryParse)
        .whereType<BluetoothFrame>()
        .where((f) => f.command == BluetoothCommand.controlMapping.id)
        .map((f) => f.data[1])
        .toList();
    expect(indexes, [10, 2, 3, 4, 5, 6, 7, 8, 9]);
    final state = container.read(rcAppStateProvider);
    expect(state.controlMapping.channel, 'CH11');
    expect(state.controlMappings.keys, containsAll(controlMappingChannels));
  });

  test('control mapping in-flight sync does not override user focus', () async {
    final transport = _DelayedControlMappingAckTransport();
    final container = ProviderContainer(
      overrides: [
        linkTransportProvider.overrideWithValue(transport),
        protocolAdapterProvider.overrideWithValue(_NoStartupProtocolAdapter()),
      ],
    );
    addTearDown(() async {
      await transport.dispose();
      container.dispose();
    });
    final notifier = container.read(rcAppStateProvider.notifier);
    notifier.startScan();
    await Future<void>.delayed(Duration.zero);
    transport.emitScanResults([
      const BluetoothScanDevice(remoteId: 'B-5', name: 'MG11 Test', rssi: -44),
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
    notifier.enterControlMappingPage();
    transport.sentPackets.clear();
    final syncFuture = notifier.refreshForScreen(Screen.controlMapping);
    await Future<void>.delayed(const Duration(milliseconds: 8));
    notifier.focusControlMappingChannel('CH6');
    final success = await syncFuture;
    expect(success, isTrue);
    final state = container.read(rcAppStateProvider);
    expect(state.controlMapping.channel, 'CH6');
  });

  test(
    'control mapping quick re-enter stays CH11 when refresh is deduplicated',
    () async {
      final transport = _RefreshAckingMemoryLinkTransport();
      final container = ProviderContainer(
        overrides: [
          linkTransportProvider.overrideWithValue(transport),
          protocolAdapterProvider.overrideWithValue(
            _NoStartupProtocolAdapter(),
          ),
        ],
      );
      addTearDown(() async {
        await transport.dispose();
        container.dispose();
      });
      final notifier = container.read(rcAppStateProvider.notifier);
      notifier.startScan();
      await Future<void>.delayed(Duration.zero);
      transport.emitScanResults([
        const BluetoothScanDevice(
          remoteId: 'B-6',
          name: 'MG11 Test',
          rssi: -44,
        ),
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
      notifier.enterControlMappingPage();
      final first = await notifier.refreshForScreen(Screen.controlMapping);
      expect(first, isTrue);
      notifier.focusControlMappingChannel('CH5');
      expect(container.read(rcAppStateProvider).controlMapping.channel, 'CH5');
      notifier.leaveControlMappingPage();
      notifier.enterControlMappingPage();
      expect(container.read(rcAppStateProvider).controlMapping.channel, 'CH11');
      final before = _sentReadCount(transport, BluetoothCommand.controlMapping);
      final second = await notifier.refreshForScreen(Screen.controlMapping);
      expect(second, isTrue);
      final after = _sentReadCount(transport, BluetoothCommand.controlMapping);
      expect(after, before);
      expect(container.read(rcAppStateProvider).controlMapping.channel, 'CH11');
    },
  );

  test('mixing reset restores four wheel steer defaults', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);
    final seeded = RcAppState.initial().copyWith(
      mixingSettings: const MixingSettings(
        activeMode: '4WS',
        enabled: true,
        ratio: 33,
        curve: 0,
        direction: '4WS_REAR_OPPOSITE',
        selectedChannel: 'CH8',
      ),
      protocol: const RcProtocolState(
        rawPayloadByCommand: <int, List<int>>{},
        curveValues: <int>[0, 0, 0],
        fourWheelSteer: FourWheelSteerSnapshot(
          enabled: true,
          channel: 7,
          ratio: 33,
          mode: 3,
        ),
      ),
    );
    notifier.state = seeded;

    await notifier.resetDefaultsForScreen(Screen.mixing);
    final next = container.read(rcAppStateProvider);

    expect(next.protocol.fourWheelSteer.enabled, isFalse);
    expect(next.protocol.fourWheelSteer.channel, 2);
    expect(next.protocol.fourWheelSteer.ratio, 100);
    expect(next.mixingSettings.activeMode, '4WS');
    expect(next.mixingSettings.enabled, isFalse);
    expect(next.mixingSettings.selectedChannel, 'CH3');
    expect(next.mixingSettings.ratio, 100);
    expect(next.mixingSettings.direction, '4WS_FRONT_SAME');
  });

  test('mixing reset all restores four wheel steer front selection', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);
    notifier.state = RcAppState.initial().copyWith(
      mixingSettings: const MixingSettings(
        activeMode: '4WS',
        enabled: true,
        ratio: 33,
        curve: 0,
        direction: '4WS_REAR_OPPOSITE',
        selectedChannel: 'CH8',
      ),
    );

    await notifier.resetDefaultsForScreen(
      Screen.mixing,
      resetAllMixingModes: true,
    );
    final next = container.read(rcAppStateProvider);

    expect(next.protocol.fourWheelSteer.mode, 0);
    expect(next.mixingSettings.activeMode, '4WS');
    expect(next.mixingSettings.direction, '4WS_FRONT_SAME');
  });

  test('mixing reset restores track mixing defaults', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);
    final seeded = RcAppState.initial().copyWith(
      mixingSettings: const MixingSettings(
        activeMode: 'TRACK',
        enabled: true,
        ratio: -65,
        curve: 0,
        direction: 'OPPOSITE',
        selectedChannel: 'CH3',
      ),
      protocol: const RcProtocolState(
        rawPayloadByCommand: <int, List<int>>{},
        curveValues: <int>[0, 0, 0],
        trackMixing: TrackMixingSnapshot(
          enabled: true,
          forwardRatio: 20,
          backwardRatio: 30,
          leftRatio: 40,
          rightRatio: 50,
        ),
      ),
    );
    notifier.state = seeded;

    await notifier.resetDefaultsForScreen(Screen.mixing);
    final next = container.read(rcAppStateProvider);

    expect(next.protocol.trackMixing.enabled, isFalse);
    expect(next.protocol.trackMixing.forwardRatio, 100);
    expect(next.protocol.trackMixing.backwardRatio, 100);
    expect(next.protocol.trackMixing.leftRatio, 100);
    expect(next.protocol.trackMixing.rightRatio, 100);
    expect(next.mixingSettings.activeMode, 'TRACK');
    expect(next.mixingSettings.enabled, isFalse);
    expect(next.mixingSettings.ratio, 100);
    expect(next.mixingSettings.direction, 'SAME');
  });

  test('dual rate reset restores all channels to 100', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);
    final seeded = RcAppState.initial().copyWith(
      channels: RcAppState.initial().channels
          .map((ch) => ch.copyWith(dualRate: 37))
          .toList(growable: false),
    );
    notifier.state = seeded;

    await notifier.resetDefaultsForScreen(Screen.dualRate);
    final next = container.read(rcAppStateProvider);

    expect(next.channels.every((ch) => ch.dualRate == 100), isTrue);
  });
}

class _NoStartupProtocolAdapter extends ProtocolAdapterV1 {
  @override
  Iterable<BluetoothCommand> startupReadCommands() {
    return const <BluetoothCommand>[];
  }
}

class _DelayedConnectMemoryLinkTransport extends MemoryLinkTransport {
  _DelayedConnectMemoryLinkTransport() : super(linkType: LinkType.usb);

  @override
  Future<void> connect(String remoteId) async {
    await Future<void>.delayed(const Duration(milliseconds: 25));
    await super.connect(remoteId);
  }
}

int _sentReadCount(MemoryLinkTransport transport, BluetoothCommand cmd) {
  return transport.sentPackets
      .map(BluetoothFrame.tryParse)
      .whereType<BluetoothFrame>()
      .where((f) => f.command == cmd.id && f.length == 0)
      .length;
}

class _RefreshAckingMemoryLinkTransport extends MemoryLinkTransport {
  _RefreshAckingMemoryLinkTransport() : super(linkType: LinkType.usb);

  @override
  Future<void> send(List<int> bytes) async {
    await super.send(bytes);
    final frame = BluetoothFrame.tryParse(bytes);
    if (frame == null) return;
    if (frame.length != 0) return;

    if (frame.command == BluetoothCommand.controlMapping.id) {
      final channelIndex = frame.data.length > 1 ? frame.data[1] : 10;
      emitIncoming(
        BluetoothFrame(
          seq: frame.seq,
          command: frame.command,
          length: 9,
          data: [0, channelIndex, 1, 0, 0, 0, 0, 1, 25],
        ).toBytes(),
      );
      return;
    }
    if (frame.command == BluetoothCommand.channelDisplay.id) {
      emitIncoming(
        BluetoothFrame(
          seq: frame.seq,
          command: frame.command,
          length: 22,
          data: List<int>.filled(24, 0),
        ).toBytes(),
      );
      return;
    }
    if (frame.command == BluetoothCommand.telemetryDisplay.id) {
      emitIncoming(
        BluetoothFrame(
          seq: frame.seq,
          command: frame.command,
          length: 12,
          data: List<int>.filled(24, 0),
        ).toBytes(),
      );
      return;
    }
    if (frame.command == BluetoothCommand.channelReverse.id) {
      emitIncoming(
        BluetoothFrame(
          seq: frame.seq,
          command: frame.command,
          length: 11,
          data: List<int>.filled(24, 0),
        ).toBytes(),
      );
    }
  }
}

class _DelayedControlMappingAckTransport extends MemoryLinkTransport {
  _DelayedControlMappingAckTransport() : super(linkType: LinkType.usb);

  @override
  Future<void> send(List<int> bytes) async {
    await super.send(bytes);
    final frame = BluetoothFrame.tryParse(bytes);
    if (frame == null || frame.length != 0) return;
    if (frame.command == BluetoothCommand.controlMapping.id) {
      await Future<void>.delayed(const Duration(milliseconds: 3));
      final channelIndex = frame.data.length > 1 ? frame.data[1] : 10;
      emitIncoming(
        BluetoothFrame(
          seq: frame.seq,
          command: frame.command,
          length: 9,
          data: [0, channelIndex, 1, 0, 0, 0, 0, 1, 25],
        ).toBytes(),
      );
      return;
    }
    if (frame.command == BluetoothCommand.channelDisplay.id) {
      emitIncoming(
        BluetoothFrame(
          seq: frame.seq,
          command: frame.command,
          length: 22,
          data: List<int>.filled(24, 0),
        ).toBytes(),
      );
      return;
    }
    if (frame.command == BluetoothCommand.telemetryDisplay.id) {
      emitIncoming(
        BluetoothFrame(
          seq: frame.seq,
          command: frame.command,
          length: 12,
          data: List<int>.filled(24, 0),
        ).toBytes(),
      );
      return;
    }
    if (frame.command == BluetoothCommand.channelReverse.id) {
      emitIncoming(
        BluetoothFrame(
          seq: frame.seq,
          command: frame.command,
          length: 11,
          data: List<int>.filled(24, 0),
        ).toBytes(),
      );
    }
  }
}

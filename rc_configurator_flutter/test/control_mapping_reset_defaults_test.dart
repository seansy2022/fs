import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/lib/protocol/protocol_adapter_v1.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_provider.dart';
import 'package:rc_configurator_flutter/src/provider/control_mapping_reset_defaults.dart';
import 'package:rc_configurator_flutter/src/types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'control mapping reset applies captured defaults for current channel',
    () async {
      final container = ProviderContainer(
        overrides: [
          linkTransportProvider.overrideWithValue(
            MemoryLinkTransport(linkType: LinkType.usb),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(rcAppStateProvider.notifier);
      notifier.state = RcAppState.initial().copyWith(
        controlMapping: const ControlMappingState(
          channel: 'CH5',
          type: '三档开关',
          action: '驱动混控',
          mode: '触发',
          controlType: ControlType.threeWaySwitch,
          availableStates: <String>['旋钮', '三档开关'],
          selectedState: '三档开关',
          functionType: '驱动混控',
          targetChannel: null,
          mixingFunction: '混动',
          mixingMode1: '驱动混控后面',
          mixingMode2: '驱动混控前面',
          mixingMode3: '驱动混控前后混控',
        ),
      );

      await notifier.resetDefaultsForScreen(Screen.controlMapping);
      final app = container.read(rcAppStateProvider);
      final next = app.controlMapping;
      final ch3 = app.controlMappings['CH3'];
      final ch5 = app.controlMappings['CH5'];

      expect(next.channel, 'CH5');
      expect(next.type, '旋钮');
      expect(next.action, 'CH5');
      expect(next.mode, '翻转');
      expect(next.selectedState, '旋钮');
      expect(next.targetChannel, 'CH5');
      expect(next.mixingFunction, isNull);
      expect(next.mixingMode1, '四轮转向');
      expect(next.mixingMode2, '四轮转向');
      expect(next.mixingMode3, '四轮转向');
      expect(ch3?.channel, 'CH3');
      expect(ch3?.targetChannel, 'CH3');
      expect(ch5?.channel, 'CH5');
      expect(ch5?.type, '旋钮');
    },
  );

  test('control mapping reset defaults emit expected payload matrix', () {
    final adapter = ProtocolAdapterV1();
    final defaults = {
      for (final s in controlMappingResetDefaults()) s.channel: s,
    };
    const expected = <String, List<int>>{
      'CH3': [0, 2, 1, 0, 0, 0, 0, 0, 2],
      'CH4': [0, 3, 1, 0, 0, 0, 0, 0, 3],
      'CH5': [0, 4, 0, 0, 0, 0, 0, 0, 4],
      'CH6': [0, 5, 0, 0, 0, 0, 0, 0, 5],
      'CH7': [0, 6, 1, 0, 0, 0, 0, 0, 6],
      'CH8': [0, 7, 1, 0, 0, 0, 0, 0, 7],
      'CH9': [0, 8, 0, 0, 0, 0, 0, 0, 8],
      'CH10': [0, 9, 1, 0, 0, 0, 0, 0, 9],
      'CH11': [0, 10, 1, 0, 0, 0, 0, 0, 10],
    };
    for (final entry in expected.entries) {
      final next = defaults[entry.key]!;
      final state = RcAppState.initial().copyWith(controlMapping: next);
      final requests = adapter.writesForIntent(
        ControlMappingUpdatedIntent(next),
        state,
      );
      expect(requests, hasLength(1));
      expect(requests.first.command, BluetoothCommand.controlMapping);
      expect(requests.first.payload, entry.value);
    }
  });

  test('control mapping reset sends CH1 and CH2 seed payloads first', () async {
    final transport = _AckingMemoryLinkTransport();
    final container = ProviderContainer(
      overrides: [linkTransportProvider.overrideWithValue(transport)],
    );
    addTearDown(() async {
      await transport.dispose();
      container.dispose();
    });
    final notifier = container.read(rcAppStateProvider.notifier);
    notifier.state = notifier.state.copyWith(
      bluetooth: notifier.state.bluetooth.copyWith(
        isConnected: true,
        connectedDeviceMac: 'U-1',
      ),
    );

    await notifier.resetDefaultsForScreen(Screen.controlMapping);

    final payloads = transport.sentPackets
        .map(BluetoothFrame.tryParse)
        .whereType<BluetoothFrame>()
        .where((f) => f.command == BluetoothCommand.controlMapping.id)
        .map((f) => f.data.sublist(0, f.length))
        .toList(growable: false);
    expect(payloads, isNotEmpty);
    expect(payloads[0], [0, 0, 0, 0, 0, 0, 0, 0, 0]);
    expect(payloads[1], [0, 1, 0, 0, 0, 0, 0, 0, 1]);
  });
}

class _AckingMemoryLinkTransport extends MemoryLinkTransport {
  _AckingMemoryLinkTransport() : super(linkType: LinkType.usb);

  @override
  Future<void> send(List<int> bytes) async {
    await super.send(bytes);
    final frame = BluetoothFrame.tryParse(bytes);
    if (frame == null) return;
    if (frame.command == BluetoothCommand.channelDisplay.id &&
        frame.length == 0) {
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
    if (frame.command == BluetoothCommand.telemetryDisplay.id &&
        frame.length == 0) {
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
    if (frame.command >= BluetoothCommand.channelReverse.id &&
        frame.command <= BluetoothCommand.systemSetting.id) {
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
}

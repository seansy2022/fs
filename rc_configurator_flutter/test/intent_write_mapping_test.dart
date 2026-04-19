import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/protocol/protocol_adapter_v1.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  _testChannelUpdatedBundle();
  _testPageScopedChannelIntents();
  _testDualRateOnly();
  _testSingleCommandIntents();
  _testMixingCommandMapping();
  _testMixingDisableWrite();
  _testBrakeCurvePayload();
  _testControlMappingPreviewNoWrite();
}

void _testChannelUpdatedBundle() {
  test('channel updated intent writes expected bundle only', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final next = state.channels.first.copyWith(dualRate: 66);
    final commands = _commandsFor(
      adapter,
      ChannelUpdatedIntent(id: next.id, next: next),
      state.copyWith(channels: [next, ...state.channels.skip(1)]),
    );
    expect(commands, [
      BluetoothCommand.channelReverse,
      BluetoothCommand.channelTravel,
      BluetoothCommand.subTrim,
      BluetoothCommand.dualRate,
      BluetoothCommand.failsafe,
    ]);
  });
}

void _testPageScopedChannelIntents() {
  test('page scoped channel intents send only one command', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final next = state.channels.first.copyWith(
      reverse: true,
      lLimit: 40,
      rLimit: 80,
      offset: 6,
      failsafeActive: true,
      failsafeValue: 12,
    );
    final current = state.copyWith(channels: [next, ...state.channels.skip(1)]);
    final cases = <MapEntry<RcAppIntent, BluetoothCommand>>[
      MapEntry(
        ChannelReverseUpdatedIntent(id: next.id, next: next),
        BluetoothCommand.channelReverse,
      ),
      MapEntry(
        ChannelTravelUpdatedIntent(id: next.id, next: next),
        BluetoothCommand.channelTravel,
      ),
      MapEntry(
        SubTrimUpdatedIntent(id: next.id, next: next),
        BluetoothCommand.subTrim,
      ),
      MapEntry(
        FailsafeUpdatedIntent(id: next.id, next: next),
        BluetoothCommand.failsafe,
      ),
    ];
    for (final c in cases) {
      expect(_commandsFor(adapter, c.key, current), [c.value]);
    }
  });
}

void _testDualRateOnly() {
  test('dual rate intent writes 0x14 only', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final next = state.channels.first.copyWith(dualRate: 80);
    final commands = _commandsFor(
      adapter,
      DualRateUpdatedIntent(id: next.id, next: next),
      state.copyWith(channels: [next, ...state.channels.skip(1)]),
    );
    expect(commands, [BluetoothCommand.dualRate]);
  });
}

void _testSingleCommandIntents() {
  test('single command intents do not trigger extra commands', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final cases = <MapEntry<RcAppIntent, BluetoothCommand>>[
      MapEntry(ModelSelectedIntent('MOD01'), BluetoothCommand.modelSwitch),
      MapEntry(
        RadioSettingsUpdatedIntent(state.radioSettings.copyWith(idleAlarm: 1)),
        BluetoothCommand.systemSetting,
      ),
      MapEntry(CurveValueUpdatedIntent(12), BluetoothCommand.curve),
      MapEntry(CurveSelectedIntent('Brake'), BluetoothCommand.curve),
      MapEntry(
        ControlMappingUpdatedIntent(
          state.controlMapping.copyWith(channel: 'CH1'),
        ),
        BluetoothCommand.controlMapping,
      ),
    ];
    for (final c in cases) {
      final commands = _commandsFor(adapter, c.key, state);
      expect(commands, [
        c.value,
      ], reason: '${c.key.runtimeType} should be single');
    }
  });
}

void _testMixingCommandMapping() {
  test('mixing settings enable writes exclusive bundle', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final expected = <String, BluetoothCommand>{
      '4WS': BluetoothCommand.fourWheelSteer,
      'TRACK': BluetoothCommand.trackMixing,
      'DRIVE': BluetoothCommand.driveMixing,
      'BRAKE': BluetoothCommand.brakeMixing,
    };
    for (final entry in expected.entries) {
      final settings = state.mixingSettings.copyWith(
        activeMode: entry.key,
        enabled: true,
        selectedChannel: 'CH1',
        ratio: 50,
        direction: 'SAME',
      );
      final commands = _commandsFor(
        adapter,
        MixingSettingsUpdatedIntent(settings),
        state.copyWith(mixingSettings: settings),
      );
      expect(commands, [
        BluetoothCommand.fourWheelSteer,
        BluetoothCommand.trackMixing,
        BluetoothCommand.driveMixing,
        BluetoothCommand.brakeMixing,
      ], reason: '${entry.key} command mismatch');
    }
    final empty = _commandsFor(
      adapter,
      MixingSettingsUpdatedIntent(
        state.mixingSettings.copyWith(activeMode: ''),
      ),
      state,
    );
    expect(empty, isEmpty);
  });
}

void _testMixingDisableWrite() {
  test('module disable writes command with enable bit = 0', () {
    final adapter = ProtocolAdapterV1();
    final base = RcAppState.initial();
    final settings = base.mixingSettings.copyWith(
      activeMode: '4WS',
      enabled: false,
      selectedChannel: 'CH3',
      ratio: 40,
      direction: 'SAME',
    );
    final state = base.copyWith(
      mixingSettings: settings,
      protocol: base.protocol.copyWith(
        fourWheelSteer: base.protocol.fourWheelSteer.copyWith(
          enabled: false,
          channel: 2,
          ratio: 40,
          mode: 0,
        ),
      ),
    );
    final requests = adapter.writesForIntent(
      MixingSettingsUpdatedIntent(settings),
      state,
    );
    expect(requests.map((e) => e.command).toList(), [
      BluetoothCommand.fourWheelSteer,
    ]);
    expect(requests.first.payload.first, 0);
  });
}

void _testBrakeCurvePayload() {
  test('brake payload writes signed curve from -100..100', () {
    final adapter = ProtocolAdapterV1();
    final base = RcAppState.initial();
    final state = base.copyWith(
      mixingSettings: base.mixingSettings.copyWith(activeMode: 'BRAKE'),
      protocol: base.protocol.copyWith(
        brakeMixing: base.protocol.brakeMixing.copyWith(
          enabled: true,
          channel: 6,
          ratio: 88,
          curve: -30,
        ),
      ),
    );
    final requests = adapter.writesForIntent(
      MixingSettingsUpdatedIntent(state.mixingSettings),
      state,
    );
    expect(requests.map((e) => e.command).toList(), [
      BluetoothCommand.brakeMixing,
    ]);
    expect(requests.first.payload[2], 6);
    expect(requests.first.payload[4], 88);
    expect(requests.first.payload[5], 226);
  });
}

void _testControlMappingPreviewNoWrite() {
  test('control mapping preview intent does not write command', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final preview = ControlMappingPreviewIntent(
      state.controlMapping.copyWith(channel: 'CH3'),
    );
    final commands = _commandsFor(adapter, preview, state);
    expect(commands, isEmpty);
  });
}

List<BluetoothCommand> _commandsFor(
  ProtocolAdapterV1 adapter,
  RcAppIntent intent,
  RcAppState state,
) {
  return adapter.writesForIntent(intent, state).map((e) => e.command).toList();
}

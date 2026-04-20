import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ble/rc_ble.dart';
import 'package:rc_configurator_flutter/src/lib/protocol/protocol_adapter_v1.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/control_mapping_options.dart';

void main() {
  test('CH6 three-way mixing payload matches CH5 three-way payload shape', () {
    final ch5Type = controlTypeOptionsForChannel('CH5').last;
    final ch6Type = controlTypeOptionsForChannel('CH6').first;
    final mixAction = functionModeOptionsForChannel('CH5', type: ch5Type)
        .firstWhere((e) => !e.startsWith('CH'));
    final mixingFunction = ch5MixingFunctionOptions.first;
    final modes = ch5DirectionOptions(mixingFunction);
    final base = RcAppState.initial().controlMapping.copyWith(
      action: mixAction,
      mixingFunction: mixingFunction,
      mixingMode1: modes[0],
      mixingMode2: modes[1],
      mixingMode3: modes[2],
    );
    final payloadCh5 = _payload(base.copyWith(channel: 'CH5', type: ch5Type));
    final payloadCh6 = _payload(base.copyWith(channel: 'CH6', type: ch6Type));
    expect(payloadCh5[1], 4);
    expect(payloadCh6[1], 5);
    expect(payloadCh6.sublist(2), payloadCh5.sublist(2));
  });

  test('CH6 mixing response is parsed as three-way with CH6 mapping', () {
    final adapter = ProtocolAdapterV1();
    final ch6Type = controlTypeOptionsForChannel('CH6').first;
    final expectedAction = functionModeOptionsForChannel('CH6', type: ch6Type)
        .firstWhere((e) => !e.startsWith('CH'));
    final frame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.controlMapping.id,
      length: 9,
      data: const [0, 5, 0, 0, 0, 1, 3, 1, 11],
    );
    final next = adapter.applyToState(RcAppState.initial(), adapter.decodeFrame(frame));
    expect(next.controlMapping.channel, 'CH6');
    expect(next.controlMapping.type, ch6Type);
    expect(next.controlMapping.selectedState, ch6Type);
    expect(next.controlMapping.action, expectedAction);
    expect(next.controlMappings['CH6']?.action, expectedAction);
    expect(next.controlMappings['CH6']?.targetChannel, isNull);
  });
}

List<int> _payload(ControlMappingState mapping) {
  final state = RcAppState.initial().copyWith(controlMapping: mapping);
  final adapter = ProtocolAdapterV1();
  final writes = adapter.writesForIntent(ControlMappingUpdatedIntent(mapping), state);
  return writes.single.payload;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/protocol/protocol_adapter_v1.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/control_mapping_options.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  test('CH5 3-Pos 4W maps to 5/6/7 and 8(12)', () {
    final state = RcAppState.initial().copyWith(
      controlMapping: RcAppState.initial().controlMapping.copyWith(
        channel: 'CH5',
        type: '3-Pos Switch',
        mixingFunction: '4W',
        mixingMode1: '4WS Front',
        mixingMode2: '4WS F/R Reverse',
        mixingMode3: '4WS Rear',
        action: '4W Mix',
      ),
    );
    final payload = _controlMappingPayload(state);
    expect(payload[4], 0);
    expect(payload[5], 1);
    expect(payload[6], 3);
    expect(payload[7], 1);
    expect(payload[8], 12);
  });

  test('CH5 3-Pos Hybrid maps to 5/6/7 and 8(14)', () {
    final state = RcAppState.initial().copyWith(
      controlMapping: RcAppState.initial().controlMapping.copyWith(
        channel: 'CH5',
        type: '3-Pos Switch',
        mixingFunction: 'Hybrid',
        mixingMode1: 'Drive Mix Rear',
        mixingMode2: 'Drive Mix F/R Hybrid',
        mixingMode3: 'Drive Mix Front',
        action: 'Drive Mix',
      ),
    );
    final payload = _controlMappingPayload(state);
    expect(payload[4], 0);
    expect(payload[5], 1);
    expect(payload[6], 2);
    expect(payload[7], 1);
    expect(payload[8], 14);
  });

  test('CH5 3-Pos select Channel Output encodes as normal function', () {
    final state = RcAppState.initial().copyWith(
      controlMapping: RcAppState.initial().controlMapping.copyWith(
        channel: 'CH5',
        type: '3-Pos Switch',
        action: 'CH8',
        targetChannel: 'CH8',
      ),
    );
    final payload = _controlMappingPayload(state);
    expect(payload[7], 0);
    expect(payload[8], 7);
  });

  test('Control mapping None function encodes as 25', () {
    final state = RcAppState.initial().copyWith(
      controlMapping: RcAppState.initial().controlMapping.copyWith(
        channel: 'CH3',
        type: 'Click',
        action: controlMappingNoAction,
      ),
    );
    final payload = _controlMappingPayload(state);
    expect(payload[7], 0);
    expect(payload[8], 25);
  });

  test('CH9 trim and ratio encode by payload[7]/[8]', () {
    const cases = <(String, int, int)>[
      ('Steering Trim', 2, 15),
      ('Throttle Trim', 2, 16),
      ('Steering Ratio', 3, 17),
      ('Forward Ratio', 3, 18),
      ('Brake Ratio', 3, 19),
      ('4WS Mix Ratio', 3, 20),
      ('Drive Mix Forward Ratio', 3, 21),
      ('Drive Mix Reverse Ratio', 3, 22),
      ('Brake Mix Ratio', 3, 23),
    ];
    for (final c in cases) {
      final state = RcAppState.initial().copyWith(
        controlMapping: RcAppState.initial().controlMapping.copyWith(
          channel: 'CH9',
          type: 'Knob',
          action: c.$1,
        ),
      );
      final payload = _controlMappingPayload(state);
      expect(payload[7], c.$2);
      expect(payload[8], c.$3);
    }
  });

  test('CH5 3-Pos response parses mix function and 3-pos direction from byte 8', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final frame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.controlMapping.id,
      length: 9,
      data: const [0, 4, 0, 0, 0, 1, 3, 1, 12],
    );
    final next = adapter.applyToState(state, adapter.decodeFrame(frame));
    expect(next.controlMapping.type, '3-Pos Switch');
    expect(next.controlMapping.mixingFunction, '4W');
    expect(next.controlMapping.mixingMode1, '4WS Front');
    expect(next.controlMapping.mixingMode2, '4WS F/R Reverse');
    expect(next.controlMapping.mixingMode3, '4WS Rear');
    expect(next.controlMapping.action, '4W Mix');
    expect(next.controlMappings['CH5']?.action, '4W Mix');
    expect(next.controlMappings['CH5']?.mixingMode3, '4WS Rear');
  });

  test('CH5 3-Pos Hybrid response parses 0/1/2 as Rear/Middle/Front', () {
    final adapter = ProtocolAdapterV1();
    final frame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.controlMapping.id,
      length: 9,
      data: const [0, 4, 0, 0, 0, 1, 2, 1, 14],
    );
    final next = adapter.applyToState(
      RcAppState.initial(),
      adapter.decodeFrame(frame),
    );
    expect(next.controlMapping.type, '3-Pos Switch');
    expect(next.controlMapping.mixingFunction, 'Hybrid');
    expect(next.controlMapping.mixingMode1, 'Drive Mix Rear');
    expect(next.controlMapping.mixingMode2, 'Drive Mix F/R Hybrid');
    expect(next.controlMapping.mixingMode3, 'Drive Mix Front');
    expect(next.controlMapping.action, 'Drive Mix');
  });

  test('CH5 old format 7/8 encoding no longer parses as mixing', () {
    final adapter = ProtocolAdapterV1();
    final frame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.controlMapping.id,
      length: 9,
      data: const [0, 4, 0, 0, 0, 1, 3, 2, 17],
    );
    final next = adapter.applyToState(
      RcAppState.initial(),
      adapter.decodeFrame(frame),
    );
    expect(next.controlMapping.action, 'Steering Trim');
    expect(next.controlMapping.mixingFunction, isNull);
  });

  test('CH5 transitional format 2/11 encoding no longer parses as mixing', () {
    final adapter = ProtocolAdapterV1();
    final frame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.controlMapping.id,
      length: 9,
      data: const [0, 4, 0, 0, 0, 1, 3, 2, 11],
    );
    final next = adapter.applyToState(
      RcAppState.initial(),
      adapter.decodeFrame(frame),
    );
    expect(next.controlMapping.action, 'Steering Trim');
    expect(next.controlMapping.mixingFunction, isNull);
  });

  test('CH5 response state 0 normalizes to Knob', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final frame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.controlMapping.id,
      length: 9,
      data: const [0, 4, 0, 0, 0, 0, 0, 0, 4],
    );
    final next = adapter.applyToState(state, adapter.decodeFrame(frame));
    expect(next.controlMapping.channel, 'CH5');
    expect(next.controlMapping.type, 'Knob');
    expect(next.controlMapping.selectedState, 'Knob');
  });

  test('CH9 response parses by trim and ratio function codes', () {
    final adapter = ProtocolAdapterV1();
    final trimFrame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.controlMapping.id,
      length: 9,
      data: const [0, 8, 0, 0, 0, 0, 0, 2, 16],
    );
    final ratioFrame = BluetoothFrame(
      seq: 2,
      command: BluetoothCommand.controlMapping.id,
      length: 9,
      data: const [0, 8, 0, 0, 0, 0, 0, 3, 24],
    );
    final trimNext = adapter.applyToState(
      RcAppState.initial(),
      adapter.decodeFrame(trimFrame),
    );
    final ratioNext = adapter.applyToState(
      RcAppState.initial(),
      adapter.decodeFrame(ratioFrame),
    );
    expect(trimNext.controlMapping.action, 'Throttle Trim');
    expect(trimNext.controlMapping.functionType, 'Throttle Trim');
    expect(ratioNext.controlMapping.action, 'Brake Mix Ratio');
    expect(ratioNext.controlMapping.functionType, 'Brake Mix Ratio');
  });

  test('Switch and toggle functions encode by payload[8] config', () {
    const cases = <(String, int)>[
      ('4WS Switch', 11),
      ('Track Mix Switch', 12),
      ('Drive Mix Switch', 13),
      ('Brake Mix Switch', 14),
      ('4WS Mode Switch', 11),
      ('Track Mix Toggle', 16),
      ('Drive Mix Toggle', 13),
      ('Brake Mix Toggle', 18),
    ];
    for (final c in cases) {
      final state = RcAppState.initial().copyWith(
        controlMapping: RcAppState.initial().controlMapping.copyWith(
          channel: 'CH11',
          type: 'Click',
          action: c.$1,
        ),
      );
      final payload = _controlMappingPayload(state);
      expect(payload[7], 1);
      expect(payload[8], c.$2);
    }
  });

  test('Switch and toggle functions parse from payload[8] response', () {
    final adapter = ProtocolAdapterV1();
    final frame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.controlMapping.id,
      length: 9,
      data: const [0, 10, 1, 0, 0, 0, 0, 1, 13],
    );
    final next = adapter.applyToState(
      RcAppState.initial(),
      adapter.decodeFrame(frame),
    );
    expect(next.controlMapping.channel, 'CH11');
    expect(next.controlMapping.action, 'Drive Mix Toggle');
    expect(next.controlMapping.functionType, 'Drive Mix Toggle');
  });
  test('duplicate control mapping batch writes previous no then current', () {
    final adapter = ProtocolAdapterV1();
    final base = RcAppState.initial().controlMapping;
    final previous = base.copyWith(
      channel: 'CH3',
      type: 'Click',
      action: controlMappingNoAction,
    );
    final current = base.copyWith(
      channel: 'CH4',
      type: 'Click',
      action: 'CH3',
      targetChannel: 'CH3',
    );

    final writes = adapter.writesForIntent(
      ControlMappingBatchUpdatedIntent([previous, current]),
      RcAppState.initial(),
    );

    expect(writes, hasLength(2));
    expect(
      writes.every((e) => e.command == BluetoothCommand.controlMapping),
      true,
    );
    expect(writes[0].payload[1], 2);
    expect(writes[0].payload[8], 25);
    expect(writes[1].payload[1], 3);
    expect(writes[1].payload[8], 2);
  });
}

List<int> _controlMappingPayload(RcAppState state) {
  final adapter = ProtocolAdapterV1();
  final writes = adapter.writesForIntent(
    ControlMappingUpdatedIntent(state.controlMapping),
    state,
  );
  return writes.single.payload;
}

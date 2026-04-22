import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/protocol/protocol_adapter_v1.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/control_mapping_options.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  test('CH5三档四轮映射到5/6/7与8(12)', () {
    final state = RcAppState.initial().copyWith(
      controlMapping: RcAppState.initial().controlMapping.copyWith(
        channel: 'CH5',
        type: '三档开关',
        mixingFunction: '四轮',
        mixingMode1: '四轮转向前面',
        mixingMode2: '四轮转向前后反向',
        mixingMode3: '四轮转向后面',
        action: '四轮混控',
      ),
    );
    final payload = _controlMappingPayload(state);
    expect(payload[4], 0);
    expect(payload[5], 1);
    expect(payload[6], 3);
    expect(payload[7], 1);
    expect(payload[8], 12);
  });

  test('CH5三档混动映射到5/6/7与8(14)', () {
    final state = RcAppState.initial().copyWith(
      controlMapping: RcAppState.initial().controlMapping.copyWith(
        channel: 'CH5',
        type: '三档开关',
        mixingFunction: '混动',
        mixingMode1: '驱动混控后面',
        mixingMode2: '驱动混控前面',
        mixingMode3: '驱动混控前后混控',
        action: '驱动混控',
      ),
    );
    final payload = _controlMappingPayload(state);
    expect(payload[4], 0);
    expect(payload[5], 1);
    expect(payload[6], 2);
    expect(payload[7], 1);
    expect(payload[8], 14);
  });

  test('CH5三档选择通道输出时按普通功能编码', () {
    final state = RcAppState.initial().copyWith(
      controlMapping: RcAppState.initial().controlMapping.copyWith(
        channel: 'CH5',
        type: '三档开关',
        action: 'CH8',
        targetChannel: 'CH8',
      ),
    );
    final payload = _controlMappingPayload(state);
    expect(payload[7], 0);
    expect(payload[8], 7);
  });

  test('控件分配无功能编码为25', () {
    final state = RcAppState.initial().copyWith(
      controlMapping: RcAppState.initial().controlMapping.copyWith(
        channel: 'CH3',
        type: '单击',
        action: controlMappingNoAction,
      ),
    );
    final payload = _controlMappingPayload(state);
    expect(payload[7], 0);
    expect(payload[8], 25);
  });

  test('CH9微调与比率按payload[7]/[8]编码', () {
    const cases = <(String, int, int)>[
      ('方向微调', 2, 15),
      ('油门微调', 2, 16),
      ('方向比率', 3, 17),
      ('前进比率', 3, 18),
      ('刹车比率', 3, 19),
      ('四轮转向混控比率', 3, 20),
      ('驱动混控前进比率', 3, 21),
      ('驱动混控后退比率', 3, 22),
      ('刹车混控比率', 3, 23),
    ];
    for (final c in cases) {
      final state = RcAppState.initial().copyWith(
        controlMapping: RcAppState.initial().controlMapping.copyWith(
          channel: 'CH9',
          type: '旋钮',
          action: c.$1,
        ),
      );
      final payload = _controlMappingPayload(state);
      expect(payload[7], c.$2);
      expect(payload[8], c.$3);
    }
  });

  test('CH5三档回包按8位解析混控功能与三档方向', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final frame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.controlMapping.id,
      length: 9,
      data: const [0, 4, 0, 0, 0, 1, 3, 1, 12],
    );
    final next = adapter.applyToState(state, adapter.decodeFrame(frame));
    expect(next.controlMapping.type, '三档开关');
    expect(next.controlMapping.mixingFunction, '四轮');
    expect(next.controlMapping.mixingMode1, '四轮转向前面');
    expect(next.controlMapping.mixingMode2, '四轮转向前后反向');
    expect(next.controlMapping.mixingMode3, '四轮转向后面');
    expect(next.controlMapping.action, '四轮混控');
    expect(next.controlMappings['CH5']?.action, '四轮混控');
    expect(next.controlMappings['CH5']?.mixingMode3, '四轮转向后面');
  });

  test('CH5旧格式7/8编码不再按混控解析', () {
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
    expect(next.controlMapping.action, '方向微调');
    expect(next.controlMapping.mixingFunction, isNull);
  });

  test('CH5过渡格式2/11编码不再按混控解析', () {
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
    expect(next.controlMapping.action, '方向微调');
    expect(next.controlMapping.mixingFunction, isNull);
  });

  test('CH5回包状态0归一化为旋钮', () {
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
    expect(next.controlMapping.type, '旋钮');
    expect(next.controlMapping.selectedState, '旋钮');
  });

  test('CH9回包按微调与比率功能码解析', () {
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
    expect(trimNext.controlMapping.action, '油门微调');
    expect(trimNext.controlMapping.functionType, '油门微调');
    expect(ratioNext.controlMapping.action, '刹车混控比率');
    expect(ratioNext.controlMapping.functionType, '刹车混控比率');
  });

  test('开关与切换功能按payload[8]配置编码', () {
    const cases = <(String, int)>[
      ('四轮转向开关', 11),
      ('履带混控开关', 12),
      ('驱动混控开关', 13),
      ('刹车混控开关', 14),
      ('四轮转向模式切换', 11),
      ('履带混控切换', 16),
      ('驱动混控切换', 13),
      ('刹车混控切换', 18),
    ];
    for (final c in cases) {
      final state = RcAppState.initial().copyWith(
        controlMapping: RcAppState.initial().controlMapping.copyWith(
          channel: 'CH11',
          type: '单击',
          action: c.$1,
        ),
      );
      final payload = _controlMappingPayload(state);
      expect(payload[7], 1);
      expect(payload[8], c.$2);
    }
  });

  test('开关与切换功能按payload[8]回包解析', () {
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
    expect(next.controlMapping.action, '驱动混控切换');
    expect(next.controlMapping.functionType, '驱动混控切换');
  });
  test('duplicate control mapping batch writes previous no then current', () {
    final adapter = ProtocolAdapterV1();
    final base = RcAppState.initial().controlMapping;
    final previous = base.copyWith(
      channel: 'CH3',
      type: '单击',
      action: controlMappingNoAction,
    );
    final current = base.copyWith(
      channel: 'CH4',
      type: '单击',
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

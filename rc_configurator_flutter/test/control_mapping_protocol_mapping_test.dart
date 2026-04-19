import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/protocol/protocol_adapter_v1.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  test('CH5三档四轮映射到5/6/7与8', () {
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
    expect(payload[7], 2);
    expect(payload[8], 17);
  });

  test('CH5三档混动映射到5/6/7与8', () {
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
    expect(payload[8], 17);
  });

  test('CH5三档回包按8位解析混控功能与三档方向', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final frame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.controlMapping.id,
      length: 9,
      data: const [0, 4, 0, 0, 0, 1, 3, 2, 17],
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

  test('开关与切换功能按payload[8]配置编码', () {
    const cases = <(String, int)>[
      ('四轮转向开关', 11),
      ('履带混控开关', 12),
      ('驱动混控开关', 13),
      ('刹车混控开关', 14),
      ('四轮转向模式切换', 15),
      ('履带混控切换', 16),
      ('驱动混控切换', 17),
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
      data: const [0, 10, 1, 0, 0, 0, 0, 1, 14],
    );
    final next = adapter.applyToState(
      RcAppState.initial(),
      adapter.decodeFrame(frame),
    );
    expect(next.controlMapping.channel, 'CH11');
    expect(next.controlMapping.action, '刹车混控开关');
    expect(next.controlMapping.functionType, '刹车混控开关');
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

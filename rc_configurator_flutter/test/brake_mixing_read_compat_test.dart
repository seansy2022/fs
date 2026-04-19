import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/protocol/protocol_adapter_v1.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  test('brake read without mixingNo uses first group when mixingNo=0', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final frame = _frame([0, 2, 0, 100, 0, 1, 6, 1, 80, 226], 10);

    final next = adapter.applyToState(state, adapter.decodeFrame(frame));
    final snap = next.protocol.brakeMixing;

    expect(snap.mixingNo, 0);
    expect(snap.enabled, isFalse);
    expect(snap.channel, 2);
    expect(snap.exponentEnabled, isFalse);
    expect(snap.ratio, 100);
    expect(snap.curve, 0);
  });

  test('brake read without mixingNo uses second group when mixingNo=1', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial().copyWith(
      protocol: RcAppState.initial().protocol.copyWith(
        brakeMixing: const BrakeMixingSnapshot(mixingNo: 1),
      ),
    );
    final frame = _frame([0, 2, 0, 100, 0, 1, 6, 1, 80, 226], 10);

    final next = adapter.applyToState(state, adapter.decodeFrame(frame));
    final snap = next.protocol.brakeMixing;

    expect(snap.mixingNo, 1);
    expect(snap.enabled, isTrue);
    expect(snap.channel, 6);
    expect(snap.exponentEnabled, isTrue);
    expect(snap.ratio, 80);
    expect(snap.curve, -30);
  });

  test('brake read with mixingNo keeps legacy parsing', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final frame = _frame([1, 1, 6, 1, 88, 226], 6);

    final next = adapter.applyToState(state, adapter.decodeFrame(frame));
    final snap = next.protocol.brakeMixing;

    expect(snap.mixingNo, 1);
    expect(snap.enabled, isTrue);
    expect(snap.channel, 6);
    expect(snap.exponentEnabled, isTrue);
    expect(snap.ratio, 88);
    expect(snap.curve, -30);
  });
}

BluetoothFrame _frame(List<int> payload, int len) {
  return BluetoothFrame(
    seq: 1,
    command: BluetoothCommand.brakeMixing.id,
    length: len,
    data: [...payload, ...List<int>.filled(24 - payload.length, 0)],
  );
}

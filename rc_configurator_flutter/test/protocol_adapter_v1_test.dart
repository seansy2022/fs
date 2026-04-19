import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/protocol/protocol_adapter_v1.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  test('A1 frame updates channel values and raw cache', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final data = List<int>.filled(24, 0);
    data[0] = 0x07;
    data[1] = 0xD0;
    final frame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.channelDisplay.id,
      length: 22,
      data: data,
    );
    final event = adapter.decodeFrame(frame);
    final next = adapter.applyToState(state, event);
    expect(next.channels.first.value, 100);
    expect(
      next.protocol.rawPayloadByCommand[BluetoothCommand.channelDisplay.id],
      hasLength(22),
    );
  });

  test('0x18 frame is stored in protocol snapshots even without UI', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final frame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.escSetting.id,
      length: 4,
      data: const [1, 0, 76, 1],
    );
    final next = adapter.applyToState(state, adapter.decodeFrame(frame));
    expect(next.protocol.escSetting.runningMode, 1);
    expect(next.protocol.escSetting.dragBrake, 76);
    expect(next.protocol.escSetting.receiverType, 1);
  });

  test('A2 fixed-layout frame updates TX voltage on dashboard', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final data = List<int>.filled(24, 0);
    data[0] = 0x00;
    data[1] = 0x34;
    final frame = BluetoothFrame(
      seq: 0xD3,
      command: BluetoothCommand.telemetryDisplay.id,
      length: 24,
      data: data,
    );
    final next = adapter.applyToState(state, adapter.decodeFrame(frame));
    expect(next.telemetry.txVoltage, 5.2);
    expect(next.telemetry.rxVoltage, -1);
    expect(next.telemetry.signalStrength, 0);
  });

  test('0x11 write ack does not overwrite reverse state', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final channels = [...state.channels];
    channels[0] = channels[0].copyWith(reverse: true);
    final frame = BluetoothFrame(
      seq: 2,
      command: BluetoothCommand.channelReverse.id,
      length: 1,
      data: const [0x20],
    );
    final next = adapter.applyToState(
      state.copyWith(channels: channels),
      adapter.decodeFrame(frame),
    );
    expect(next.channels.first.reverse, true);
    expect(
      next.protocol.rawPayloadByCommand.containsKey(
        BluetoothCommand.channelReverse.id,
      ),
      isFalse,
    );
  });

  test('dual rate intent writes only 0x14 command', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial();
    final channels = [...state.channels];
    channels[0] = channels[0].copyWith(dualRate: 66);
    channels[1] = channels[1].copyWith(dualRate: 77);
    channels[2] = channels[2].copyWith(dualRate: 88);

    final writes = adapter.writesForIntent(
      DualRateUpdatedIntent(id: 'CH1', next: channels[0]),
      state.copyWith(channels: channels),
    );

    expect(writes, hasLength(1));
    expect(writes.first.command, BluetoothCommand.dualRate);
    expect(writes.first.payload, [66, 0, 77, 88]);
  });

  test('control mapping read keeps selected channel for invalid channel', () {
    final adapter = ProtocolAdapterV1();
    final state = RcAppState.initial().copyWith(
      controlMapping: RcAppState.initial().controlMapping.copyWith(
        channel: 'CH3',
      ),
    );
    final frame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.controlMapping.id,
      length: 9,
      data: const [0, 0, 1, 0, 0, 1, 2, 0, 0],
    );
    final next = adapter.applyToState(state, adapter.decodeFrame(frame));
    expect(next.controlMapping.channel, 'CH3');
    expect(next.controlMapping.action, '通道输出');
    expect(next.controlMapping.targetChannel, isNull);
  });

  test('mixing read keeps only one mode enabled', () {
    final adapter = ProtocolAdapterV1();
    var state = RcAppState.initial();
    final fourWheelFrame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.fourWheelSteer.id,
      length: 4,
      data: const [1, 2, 100, 0],
    );
    state = adapter.applyToState(state, adapter.decodeFrame(fourWheelFrame));
    expect(state.protocol.fourWheelSteer.enabled, isTrue);
    expect(state.protocol.trackMixing.enabled, isFalse);
    expect(state.protocol.driveMixing.enabled, isFalse);
    expect(state.protocol.brakeMixing.enabled, isFalse);

    final driveFrame = BluetoothFrame(
      seq: 2,
      command: BluetoothCommand.driveMixing.id,
      length: 5,
      data: const [1, 2, 100, 80, 0],
    );
    state = adapter.applyToState(state, adapter.decodeFrame(driveFrame));
    expect(state.protocol.fourWheelSteer.enabled, isFalse);
    expect(state.protocol.trackMixing.enabled, isFalse);
    expect(state.protocol.driveMixing.enabled, isTrue);
    expect(state.protocol.brakeMixing.enabled, isFalse);
  });
}

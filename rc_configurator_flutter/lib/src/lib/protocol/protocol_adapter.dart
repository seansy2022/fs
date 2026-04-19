import 'package:rc_ble/rc_ble.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/types.dart';

class ProtocolWriteRequest {
  const ProtocolWriteRequest({required this.command, required this.payload});
  final BluetoothCommand command;
  final List<int> payload;
}

class ProtocolFrameEvent {
  const ProtocolFrameEvent({
    required this.frame,
    required this.command,
    this.ack,
    this.channelSnapshot,
    this.telemetryPacket,
    this.passthroughPacket,
  });

  final BluetoothFrame frame;
  final BluetoothCommand? command;
  final AckResult? ack;
  final ChannelSnapshot? channelSnapshot;
  final TelemetryPacket? telemetryPacket;
  final PassthroughPacket? passthroughPacket;
}

abstract class ProtocolAdapter {
  BluetoothFrame encodeRead({
    required int seq,
    required BluetoothCommand command,
  });

  BluetoothFrame encodeWrite({
    required int seq,
    required BluetoothCommand command,
    required List<int> payload,
  });

  ProtocolFrameEvent decodeFrame(BluetoothFrame frame);

  RcAppState applyToState(RcAppState state, ProtocolFrameEvent event);

  Iterable<BluetoothCommand> startupReadCommands();

  Iterable<BluetoothCommand> readCommandsForScreen(Screen screen);

  List<ProtocolWriteRequest> writesForIntent(
    RcAppIntent intent,
    RcAppState state,
  );
}

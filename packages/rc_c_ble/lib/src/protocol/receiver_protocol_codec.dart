import 'dart:typed_data';

import '../models/receiver_models.dart';
import 'receiver_command.dart';
import 'receiver_frame.dart';

ReceiverFrame buildReceiverInfoRequest() {
  return ReceiverFrame(
    command: ReceiverCommand.receiverInfo.id,
    data: List<int>.filled(8, 0, growable: false),
  );
}

ReceiverInfo parseReceiverInfoResponse(
  ReceiverFrame frame, {
  String? remoteId,
}) {
  _requireCommand(frame, ReceiverCommand.receiverInfo);
  _requireDataLength(frame, 8);
  final rfmId = Uint8List.fromList(frame.data.sublist(0, 4));
  return ReceiverInfo(
    rfmId: rfmId,
    productModelCode: decodeWord(frame.data[4], frame.data[5]),
    batteryLevel: frame.data[6] & 0xFF,
    remoteId: remoteId,
  );
}

ReceiverFrame buildControlHeartbeatFrame(
  Uint8List rfmId,
  ReceiverControlValues values,
) {
  final sanitized = values.sanitize();
  final data = <int>[
    ...rfmId,
    ...encodeWord(sanitized.throttle),
    ...encodeWord(sanitized.steering),
    for (final channel in sanitized.auxChannels.take(8)) ...encodeWord(channel),
  ];
  return ReceiverFrame(
    command: ReceiverCommand.controlHeartbeat.id,
    data: data,
  );
}

ReceiverFrame buildReadFailsafeRequest(Uint8List rfmId) {
  return ReceiverFrame(
    command: ReceiverCommand.readFailsafe.id,
    data: <int>[...rfmId, ...List<int>.filled(20, 0, growable: false)],
  );
}

ReceiverFailsafeConfig parseFailsafeResponse(ReceiverFrame frame) {
  final cmd = ReceiverCommand.fromId(frame.command);
  if (cmd != ReceiverCommand.readFailsafe &&
      cmd != ReceiverCommand.writeFailsafe) {
    throw ArgumentError(
      'Unexpected failsafe command: 0x${frame.command.toRadixString(16)}',
    );
  }
  _requireDataLength(frame, 8);
  return ReceiverFailsafeConfig(
    throttleUs: decodeWord(frame.data[4], frame.data[5]),
    steeringUs: decodeWord(frame.data[6], frame.data[7]),
  );
}

ReceiverFrame buildWriteFailsafeRequest(
  Uint8List rfmId,
  ReceiverFailsafeConfig config,
) {
  return ReceiverFrame(
    command: ReceiverCommand.writeFailsafe.id,
    data: <int>[
      ...rfmId,
      ...encodeWord(config.throttleUs),
      ...encodeWord(config.steeringUs),
      ...List<int>.filled(16, 0, growable: false),
    ],
  );
}

ReceiverFrame buildFirmwareInfoRequest(Uint8List rfmId) {
  return ReceiverFrame(
    command: ReceiverCommand.firmwareInfo.id,
    data: <int>[...rfmId, ...List<int>.filled(4, 0, growable: false)],
  );
}

ReceiverFirmwareInfo parseFirmwareInfoResponse(ReceiverFrame frame) {
  _requireCommand(frame, ReceiverCommand.firmwareInfo);
  _requireDataLength(frame, 8);
  return ReceiverFirmwareInfo(
    productModelCode: decodeWord(frame.data[4], frame.data[5]),
    firmwareVersionCode: decodeWord(frame.data[6], frame.data[7]),
  );
}

ReceiverFrame buildUpgradeBootRequest(Uint8List rfmId) {
  return ReceiverFrame(
    command: ReceiverCommand.startUpgradeBoot.id,
    data: <int>[...rfmId, 0, 0, 0, 0],
  );
}

ReceiverFrame buildUpgradeLengthRequest(int length) {
  return ReceiverFrame(
    command: ReceiverCommand.setUpgradeLength.id,
    data: <int>[...encodeDWord(length), 0, 0, 0, 0],
  );
}

ReceiverFrame buildUpgradeChunkRequest(int sequence, List<int> chunk) {
  final payload = List<int>.filled(24, 0, growable: false);
  for (var index = 0; index < chunk.length && index < 24; index++) {
    payload[index] = chunk[index] & 0xFF;
  }
  return ReceiverFrame(
    command: ReceiverCommand.sendUpgradeChunk.id,
    data: <int>[sequence & 0xFF, ...payload],
  );
}

int parseUpgradeState(ReceiverFrame frame, {required int stateIndex}) {
  _requireDataLength(frame, stateIndex + 1);
  return frame.data[stateIndex] & 0xFF;
}

int parseUpgradeChunkSequence(ReceiverFrame frame) {
  _requireCommand(frame, ReceiverCommand.sendUpgradeChunk);
  _requireDataLength(frame, 2);
  return frame.data[0] & 0xFF;
}

int parseUpgradeChunkState(ReceiverFrame frame) {
  _requireCommand(frame, ReceiverCommand.sendUpgradeChunk);
  _requireDataLength(frame, 2);
  return frame.data[1] & 0xFF;
}

List<int> encodeWord(int value) {
  final normalized = value.clamp(0, 0xFFFF);
  return <int>[(normalized >> 8) & 0xFF, normalized & 0xFF];
}

List<int> encodeDWord(int value) {
  final normalized = value.clamp(0, 0xFFFFFFFF);
  return <int>[
    (normalized >> 24) & 0xFF,
    (normalized >> 16) & 0xFF,
    (normalized >> 8) & 0xFF,
    normalized & 0xFF,
  ];
}

int decodeWord(int high, int low) {
  return ((high & 0xFF) << 8) | (low & 0xFF);
}

void _requireCommand(ReceiverFrame frame, ReceiverCommand command) {
  if (frame.command != command.id) {
    throw ArgumentError(
      'Unexpected command: 0x${frame.command.toRadixString(16)}',
    );
  }
}

void _requireDataLength(ReceiverFrame frame, int minimumLength) {
  if (frame.data.length < minimumLength) {
    throw ArgumentError('Frame payload is too short: ${frame.data.length}');
  }
}

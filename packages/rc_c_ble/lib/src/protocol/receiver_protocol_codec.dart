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

ReceiverInfo parseHeartbeatReceiverInfo(
  ReceiverFrame frame, {
  String? remoteId,
  ReceiverInfo? previous,
}) {
  _requireCommand(frame, ReceiverCommand.controlHeartbeat);
  _requireDataLength(frame, 4);
  final rfmId = Uint8List.fromList(frame.data.sublist(0, 4));
  return ReceiverInfo(
    rfmId: rfmId,
    productModelCode: previous?.productModelCode ?? 0,
    batteryLevel: previous?.batteryLevel ?? 0,
    remoteId: remoteId ?? previous?.remoteId,
  );
}

ReceiverFrame buildControlHeartbeatFrame(
  Uint8List rfmId,
  ReceiverControlValues values,
) {
  final sanitized = values.sanitize();
  final data = <int>[
    ...rfmId,
    // 0x02 协议规定 CH2 方向在前，CH1 油门紧随其后。
    ...encodeWord(sanitized.steering),
    ...encodeWord(sanitized.throttle),
    for (final channel in sanitized.auxChannels.take(8)) ...encodeWord(channel),
  ];
  return ReceiverFrame(
    command: ReceiverCommand.controlHeartbeat.id,
    data: data,
  );
}

/// 构建退出接收机蓝牙模式指令，协议不携带接收机 ID 或业务数据。
ReceiverFrame buildExitBleModeRequest() {
  return ReceiverFrame(
    command: ReceiverCommand.exitBleMode.id,
    data: const <int>[],
  );
}

/// 解析退出蓝牙模式应答中的状态码，1 表示接收机已成功处理指令。
int parseExitBleModeState(ReceiverFrame frame) {
  _requireCommand(frame, ReceiverCommand.exitBleMode);
  _requireDataLength(frame, 1);
  return frame.data.first & 0xFF;
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
  final payload = List<int>.filled(23, 0, growable: false);
  for (var index = 0; index < chunk.length && index < 23; index++) {
    payload[index] = chunk[index] & 0xFF;
  }
  return ReceiverFrame(
    command: ReceiverCommand.sendUpgradeChunk.id,
    data: <int>[...encodeWord(sequence), ...payload],
  );
}

int parseUpgradeState(ReceiverFrame frame, {required int stateIndex}) {
  _requireDataLength(frame, stateIndex + 1);
  return frame.data[stateIndex] & 0xFF;
}

int parseUpgradeChunkSequence(ReceiverFrame frame) {
  _requireCommand(frame, ReceiverCommand.sendUpgradeChunk);
  _requireDataLength(frame, 3);
  return decodeWord(frame.data[0], frame.data[1]);
}

int parseUpgradeChunkState(ReceiverFrame frame) {
  _requireCommand(frame, ReceiverCommand.sendUpgradeChunk);
  _requireDataLength(frame, 3);
  return frame.data[2] & 0xFF;
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

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

ReceiverFrame buildReadFailsafeRequest(Uint8List rfmId) {
  return ReceiverFrame(
    command: ReceiverCommand.readFailsafe.id,
    data: <int>[...rfmId, ...List<int>.filled(20, 0, growable: false)],
  );
}

const _failsafeSteeringHoldFlag = 0x01;
const _failsafeThrottleHoldFlag = 0x02;
const _failsafeCh3HoldFlag = 0x04;
const _failsafeCh4HoldFlag = 0x08;
const _failsafeHoldFlagDataIndex = 23;

ReceiverFailsafeConfig parseFailsafeResponse(ReceiverFrame frame) {
  final cmd = ReceiverCommand.fromId(frame.command);
  if (cmd != ReceiverCommand.readFailsafe &&
      cmd != ReceiverCommand.writeFailsafe) {
    throw ArgumentError(
      'Unexpected failsafe command: 0x${frame.command.toRadixString(16)}',
    );
  }
  _requireDataLength(frame, _failsafeHoldFlagDataIndex + 1);
  final holdFlags = frame.data[_failsafeHoldFlagDataIndex];
  return ReceiverFailsafeConfig(
    // 0x07/0x08 协议中 CH2 方向在前，CH1 油门在后。
    steeringUs: decodeWord(frame.data[4], frame.data[5]),
    throttleUs: decodeWord(frame.data[6], frame.data[7]),
    ch3Us: decodeWord(frame.data[8], frame.data[9]),
    ch4Us: decodeWord(frame.data[10], frame.data[11]),
    steeringHold: holdFlags & _failsafeSteeringHoldFlag != 0,
    throttleHold: holdFlags & _failsafeThrottleHoldFlag != 0,
    ch3Hold: holdFlags & _failsafeCh3HoldFlag != 0,
    ch4Hold: holdFlags & _failsafeCh4HoldFlag != 0,
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
      ...encodeWord(config.steeringUs),
      ...encodeWord(config.throttleUs),
      // 0x08 的 CH3、CH4 紧随 CH2 方向和 CH1 油门。
      ...encodeWord(config.ch3Us),
      ...encodeWord(config.ch4Us),
      ...List<int>.filled(11, 0, growable: false),
      _buildFailsafeHoldFlags(config),
    ],
  );
}

/// 将四路保持状态编码到失控保护 Data[23] 的低四位。
int _buildFailsafeHoldFlags(ReceiverFailsafeConfig config) {
  var flags = 0;
  if (config.steeringHold) flags |= _failsafeSteeringHoldFlag;
  if (config.throttleHold) flags |= _failsafeThrottleHoldFlag;
  if (config.ch3Hold) flags |= _failsafeCh3HoldFlag;
  if (config.ch4Hold) flags |= _failsafeCh4HoldFlag;
  return flags;
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

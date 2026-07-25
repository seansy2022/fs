import 'dart:typed_data';

import '../models/receiver_models.dart';
import 'receiver_command.dart';
import 'receiver_frame.dart';
import 'receiver_protocol_codec.dart';

const _failsafeDataLength = 24;
const _failsafeFixedMinUs = 900;
const _failsafeFixedMaxUs = 2100;
const _failsafeDisplayValueUs = 1500;

/// 构建读取失控保护请求，除 RFM ID 外的 Data 字节按协议填零。
ReceiverFrame buildReadFailsafeRequest(Uint8List rfmId) {
  return ReceiverFrame(
    command: ReceiverCommand.readFailsafe.id,
    data: <int>[...rfmId, ...List<int>.filled(20, 0, growable: false)],
  );
}

/// 解析读取或设置应答；每路的 0xFFFF 表示保持状态。
ReceiverFailsafeConfig parseFailsafeResponse(ReceiverFrame frame) {
  final command = ReceiverCommand.fromId(frame.command);
  if (command != ReceiverCommand.readFailsafe &&
      command != ReceiverCommand.writeFailsafe) {
    throw ArgumentError(
      'Unexpected failsafe command: 0x${frame.command.toRadixString(16)}',
    );
  }
  if (frame.data.length < _failsafeDataLength) {
    throw ArgumentError('Failsafe payload is too short: ${frame.data.length}');
  }
  final channels = List<int>.generate(
    10,
    (index) => _readFailsafeChannel(frame.data, 4 + index * 2),
    growable: false,
  );
  return ReceiverFailsafeConfig(
    steeringUs: _displayValue(channels[0]),
    throttleUs: _displayValue(channels[1]),
    ch3Us: _displayValue(channels[2]),
    ch4Us: _displayValue(channels[3]),
    steeringHold: channels[0] == ReceiverFailsafeConfig.holdValue,
    throttleHold: channels[1] == ReceiverFailsafeConfig.holdValue,
    ch3Hold: channels[2] == ReceiverFailsafeConfig.holdValue,
    ch4Hold: channels[3] == ReceiverFailsafeConfig.holdValue,
    ch5ToCh10Raw: channels.sublist(4),
  );
}

/// 构建全量失控保护设置请求，未在 App 中配置的 CH5–CH10 原样回写。
ReceiverFrame buildWriteFailsafeRequest(
  Uint8List rfmId,
  ReceiverFailsafeConfig config,
) {
  if (config.ch5ToCh10Raw.length != 6) {
    throw ArgumentError.value(
      config.ch5ToCh10Raw,
      'ch5ToCh10Raw',
      '必须包含 CH5–CH10 六路数据',
    );
  }
  return ReceiverFrame(
    command: ReceiverCommand.writeFailsafe.id,
    data: <int>[
      ...rfmId,
      ..._encodeFailsafeChannel(config.steeringUs, config.steeringHold),
      ..._encodeFailsafeChannel(config.throttleUs, config.throttleHold),
      ..._encodeFailsafeChannel(config.ch3Us, config.ch3Hold),
      ..._encodeFailsafeChannel(config.ch4Us, config.ch4Hold),
      for (final rawValue in config.ch5ToCh10Raw)
        ..._encodeRawChannel(rawValue),
    ],
  );
}

int _readFailsafeChannel(List<int> data, int index) {
  final value = decodeWord(data[index], data[index + 1]);
  _validateChannelValue(value);
  return value;
}

int _displayValue(int value) {
  return value == ReceiverFailsafeConfig.holdValue
      ? _failsafeDisplayValueUs
      : value;
}

List<int> _encodeFailsafeChannel(int valueUs, bool hold) {
  if (hold) return const <int>[0xFF, 0xFF];
  _validateChannelValue(valueUs);
  return encodeWord(valueUs);
}

List<int> _encodeRawChannel(int value) {
  _validateChannelValue(value);
  return encodeWord(value);
}

void _validateChannelValue(int value) {
  if (value == ReceiverFailsafeConfig.holdValue) return;
  if (value < _failsafeFixedMinUs || value > _failsafeFixedMaxUs) {
    throw ArgumentError.value(value, 'value', '失控保护通道值必须为 900–2100 或 0xFFFF');
  }
}

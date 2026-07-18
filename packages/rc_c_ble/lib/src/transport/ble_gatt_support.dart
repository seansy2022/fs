import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'receiver_logging.dart';

const _customIoServiceUuidSuffix = '0a0b0c0d1910';
const _customNotifyUuidSuffix = '0a0b0c0d2b10';
const _customWriteUuidSuffix = '0a0b0c0d2b11';

typedef ReceiverIoPair = ({
  BluetoothCharacteristic write,
  BluetoothCharacteristic notify,
});

/// 判断 GATT 属性表句柄已失效的 Android 原生错误。
bool isGattInvalidHandleError(Object error) {
  return error.toString().contains('GATT_INVALID_HANDLE');
}

/// 清理 Android GATT 缓存后重建连接，使下一次服务发现获得最新属性句柄。
Future<void> refreshReceiverGattConnection(BluetoothDevice device) async {
  if (!Platform.isAndroid) {
    return;
  }
  ReceiverLogging.link(
    'clear gatt cache remoteId=${device.remoteId.str}',
    scope: 'FlutterBlueReceiverTransport',
  );
  try {
    await device.clearGattCache();
  } catch (error, stackTrace) {
    ReceiverLogging.link(
      'clear gatt cache failed remoteId=${device.remoteId.str} '
      'error=$error\n$stackTrace',
      scope: 'FlutterBlueReceiverTransport',
    );
    rethrow;
  }
  ReceiverLogging.link(
    'clear gatt cache completed; disconnect remoteId=${device.remoteId.str}',
    scope: 'FlutterBlueReceiverTransport',
  );
  await device.disconnect();
  // 设备端需要先完成断开；插件仍会额外保证 Android 的连接间隔。
  await Future<void>.delayed(const Duration(milliseconds: 700));
  await device.connect(timeout: const Duration(seconds: 12));
  ReceiverLogging.link(
    'gatt cache retry connected remoteId=${device.remoteId.str}',
    scope: 'FlutterBlueReceiverTransport',
  );
}

/// 从服务列表中找出协议约定的自定义收发特征对。
ReceiverIoPair? findCustomReceiverIoPair(List<BluetoothService> services) {
  for (final service in services) {
    final serviceMatch = _uuidSuffixMatches(
      service.serviceUuid.str,
      _customIoServiceUuidSuffix,
    );
    ReceiverLogging.link(
      'custom pair service=${service.serviceUuid.str} serviceMatch=$serviceMatch',
      scope: 'FlutterBlueReceiverTransport',
    );
    if (!serviceMatch) {
      continue;
    }
    BluetoothCharacteristic? writeCharacteristic;
    BluetoothCharacteristic? notifyCharacteristic;
    for (final characteristic in service.characteristics) {
      final uuid = characteristic.characteristicUuid.str;
      final writeMatch = _uuidSuffixMatches(uuid, _customWriteUuidSuffix);
      final notifyMatch = _uuidSuffixMatches(uuid, _customNotifyUuidSuffix);
      ReceiverLogging.link(
        'custom pair char=$uuid writeMatch=$writeMatch notifyMatch=$notifyMatch',
        scope: 'FlutterBlueReceiverTransport',
      );
      if (writeMatch) {
        writeCharacteristic = characteristic;
      }
      if (notifyMatch) {
        notifyCharacteristic = characteristic;
      }
    }
    ReceiverLogging.link(
      'custom pair resolved '
      'write=${writeCharacteristic?.characteristicUuid.str} '
      'notify=${notifyCharacteristic?.characteristicUuid.str}',
      scope: 'FlutterBlueReceiverTransport',
    );
    if (writeCharacteristic != null && notifyCharacteristic != null) {
      return (write: writeCharacteristic, notify: notifyCharacteristic);
    }
  }
  return null;
}

/// 按服务与 CCCD 能力从候选特征中选择稳定的收发目标。
BluetoothCharacteristic? pickReceiverIoCharacteristic(
  List<BluetoothCharacteristic> candidates, {
  String? preferredService,
  bool preferCccd = false,
}) {
  if (candidates.isEmpty) {
    return null;
  }
  BluetoothCharacteristic? best;
  var bestScore = -1;
  for (final candidate in candidates) {
    var score = 0;
    if (!isSystemBleService(candidate.serviceUuid.str)) {
      score += 100;
    }
    if (preferredService != null &&
        candidate.serviceUuid.str == preferredService) {
      score += 50;
    }
    if (preferCccd && _hasCccd(candidate)) {
      score += 20;
    }
    if (score > bestScore) {
      best = candidate;
      bestScore = score;
    }
  }
  return best;
}

/// 系统服务不作为兜底的自定义收发通道。
bool isSystemBleService(String uuid) {
  final value = uuid.toLowerCase();
  return value == '00001800-0000-1000-8000-00805f9b34fb' ||
      value == '00001801-0000-1000-8000-00805f9b34fb';
}

bool _uuidSuffixMatches(String uuid, String suffix) =>
    uuid.toLowerCase().replaceAll('-', '').endsWith(suffix);

bool _hasCccd(BluetoothCharacteristic characteristic) {
  return characteristic.descriptors.any(
    (descriptor) =>
        descriptor.descriptorUuid.str.toLowerCase() ==
        '00002902-0000-1000-8000-00805f9b34fb',
  );
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../core/providers.dart';
import 'bluetooth_domain_provider.dart';

enum ReceiverBleModeExitResult { success, notConnected, failed }

final receiverBleModeControllerProvider = Provider<ReceiverBleModeController>((
  ref,
) {
  return ReceiverBleModeController(ref);
});

class ReceiverBleModeController {
  const ReceiverBleModeController(this.ref);

  final Ref ref;

  bool get isConnected =>
      ref.read(receiverRepositoryProvider).connectionState ==
      ReceiverConnectionState.connected;

  /// 退出接收机蓝牙模式；仅在设备无应答超时时按退出成功继续断开连接。
  Future<ReceiverBleModeExitResult> exitBleModeAndDisconnect() async {
    if (!isConnected) {
      return ReceiverBleModeExitResult.notConnected;
    }

    try {
      await ref.read(receiverRepositoryProvider).exitBleMode();
    } on TimeoutException {
      // 接收机可能先离开蓝牙模式再回包，超时按退出成功继续断开连接。
    } catch (_) {
      return ReceiverBleModeExitResult.failed;
    }

    final disconnected = await ref
        .read(bluetoothDomainControllerProvider.notifier)
        .disconnect();
    if (!disconnected) {
      return ReceiverBleModeExitResult.failed;
    }
    return ReceiverBleModeExitResult.success;
  }
}

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

  Future<ReceiverBleModeExitResult> exitBleModeAndDisconnect() async {
    if (!isConnected) {
      return ReceiverBleModeExitResult.notConnected;
    }

    try {
      await ref.read(receiverRepositoryProvider).exitBleMode();
    } catch (_) {
      // The receiver may leave BLE mode before replying, so a timeout here
      // does not necessarily mean the operation failed.
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

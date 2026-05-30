import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../core/providers.dart';
import 'simulated_bluetooth_provider.dart';

final effectiveReceiverConnectionProvider = Provider<ReceiverConnectionState>((
  ref,
) {
  final real =
      ref.watch(receiverConnectionProvider).valueOrNull ??
      ReceiverConnectionState.disconnected;
  if (real != ReceiverConnectionState.disconnected) {
    return real;
  }
  if (!ref.watch(simulatedBluetoothEnabledProvider)) {
    return real;
  }
  return ref.watch(simulatedConnectionStateProvider).valueOrNull ?? real;
});

final effectiveReceiverInfoProvider = Provider<ReceiverInfo?>((ref) {
  final real = ref.watch(receiverInfoProvider).valueOrNull;
  if (real != null) {
    return real;
  }
  if (ref.watch(effectiveReceiverConnectionProvider) !=
      ReceiverConnectionState.connected) {
    return null;
  }
  return ref.watch(simulatedReceiverInfoProvider).valueOrNull;
});

final effectiveConnectedRssiProvider = Provider<int?>((ref) {
  final real = ref.watch(connectedRssiProvider).valueOrNull;
  if (real != null) {
    return real;
  }
  if (ref.watch(effectiveReceiverConnectionProvider) !=
      ReceiverConnectionState.connected) {
    return null;
  }
  return ref.watch(simulatedConnectedRssiProvider).valueOrNull;
});

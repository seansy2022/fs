import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../core/providers.dart';
import '../features/bluetooth/controllers/device_history_controller.dart';
import 'bluetooth_domain_provider.dart';
import 'effective_bluetooth_provider.dart';

class GlobalReconnectState {
  const GlobalReconnectState({
    required this.active,
    this.deviceName,
    this.startedAt,
  });

  const GlobalReconnectState.idle()
    : active = false,
      deviceName = null,
      startedAt = null;

  final bool active;
  final String? deviceName;
  final DateTime? startedAt;

  GlobalReconnectState copyWith({
    bool? active,
    String? deviceName,
    DateTime? startedAt,
    bool clearDeviceName = false,
    bool clearStartedAt = false,
  }) {
    return GlobalReconnectState(
      active: active ?? this.active,
      deviceName: clearDeviceName ? null : (deviceName ?? this.deviceName),
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
    );
  }
}

final globalReconnectControllerProvider =
    StateNotifierProvider<GlobalReconnectController, GlobalReconnectState>((
      ref,
    ) {
      final controller = GlobalReconnectController(ref);
      ref.listen<ReceiverConnectionState>(effectiveReceiverConnectionProvider, (
        previous,
        next,
      ) {
        unawaited(
          Future<void>(
            () => controller.handleConnectionTransition(previous, next),
          ),
        );
      });
      return controller;
    });

class GlobalReconnectController extends StateNotifier<GlobalReconnectState> {
  GlobalReconnectController(this.ref)
    : super(const GlobalReconnectState.idle());

  final Ref ref;
  static const _attemptTimeout = Duration(seconds: 5);
  static const _retryGap = Duration(milliseconds: 300);
  bool _cancelRequested = false;

  Future<void> handleConnectionTransition(
    ReceiverConnectionState? previous,
    ReceiverConnectionState next,
  ) async {
    if (!mounted) {
      return;
    }
    if (previous == null || previous == next) {
      return;
    }
    if (next == ReceiverConnectionState.connected) {
      _finish();
      return;
    }
    if (previous != ReceiverConnectionState.connected ||
        next != ReceiverConnectionState.disconnected ||
        state.active) {
      return;
    }
    final bluetooth = ref.read(bluetoothDomainControllerProvider.notifier);
    if (bluetooth.consumeGlobalReconnectSuppressed()) {
      return;
    }
    final remembered = ref.read(rememberedDevicesProvider);
    if (remembered.isEmpty) {
      return;
    }
    _cancelRequested = false;
    if (!mounted) {
      return;
    }
    _setAttemptState(remembered.first);
    unawaited(_retryLoop());
  }

  Future<void> cancel() async {
    if (!state.active) {
      return;
    }
    _cancelRequested = true;
    await ref
        .read(bluetoothDomainControllerProvider.notifier)
        .cancelPendingAutoReconnect();
    _finish();
  }

  Future<void> _retryLoop() async {
    while (mounted && state.active && !_cancelRequested) {
      _setAttemptState(ref.read(rememberedDevicesProvider).first);
      final connected = await ref
          .read(bluetoothDomainControllerProvider.notifier)
          .autoReconnectLastDevice(
            timeout: _attemptTimeout,
            queueUnavailablePrompt: false,
          );
      if (!mounted || _cancelRequested) {
        break;
      }
      if (connected ||
          ref.read(effectiveReceiverConnectionProvider) ==
              ReceiverConnectionState.connected) {
        break;
      }
      await Future<void>.delayed(_retryGap);
    }
    _finish();
  }

  void _setAttemptState(RememberedReceiver device) {
    state = state.copyWith(
      active: true,
      deviceName: device.name.trim().isEmpty ? device.remoteId : device.name,
      startedAt: DateTime.now(),
    );
  }

  void _finish() {
    if (!mounted) {
      return;
    }
    state = const GlobalReconnectState.idle();
  }
}

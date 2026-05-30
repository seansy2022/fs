import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import 'app_settings_provider.dart';
import 'effective_bluetooth_provider.dart';
import 'signal_strength_utils.dart';

final batteryLowAlertVisibleProvider = Provider<bool>((ref) {
  if (!ref.watch(appSettingsLoadedProvider)) {
    return false;
  }
  final settings = ref.watch(appSettingsProvider);
  final batteryLevel = ref.watch(effectiveReceiverInfoProvider)?.batteryLevel;
  return batteryLevel != null && batteryLevel < settings.batteryAlertPercent;
});

final signalLowAlertVisibleProvider = Provider<bool>((ref) {
  if (!ref.watch(appSettingsLoadedProvider)) {
    return false;
  }
  final settings = ref.watch(appSettingsProvider);
  final connection = ref.watch(effectiveReceiverConnectionProvider);
  final rssi = ref.watch(effectiveConnectedRssiProvider);
  return connection == ReceiverConnectionState.connected &&
      rssiToPercent(rssi) < settings.signalThreshold;
});

final controlPageAlertMessageProvider = Provider<String?>((ref) {
  final messages = <String>[
    if (ref.watch(batteryLowAlertVisibleProvider)) '电量低！',
    if (ref.watch(signalLowAlertVisibleProvider)) '信号低！',
  ];
  if (messages.isEmpty) {
    return null;
  }
  return messages.join(' ');
});

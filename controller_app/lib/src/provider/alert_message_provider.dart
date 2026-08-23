import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../core/localization/app_localizations.dart';
import 'app_settings_provider.dart';
import 'device_status_provider.dart';
import 'effective_bluetooth_provider.dart';
import 'signal_strength_utils.dart';

final batteryLowAlertVisibleProvider = Provider<bool>((ref) {
  if (!ref.watch(appSettingsLoadedProvider)) {
    return false;
  }
  final settings = ref.watch(appSettingsProvider);
  final batteryStatus = ref.watch(receiverBatteryStatusProvider);
  return batteryStatus?.isAtOrBelow(settings.batteryAlertPercent) ?? false;
});

final signalLowAlertVisibleProvider = Provider<bool>((ref) {
  if (!ref.watch(appSettingsLoadedProvider)) {
    return false;
  }
  final settings = ref.watch(appSettingsProvider);
  final connection = ref.watch(effectiveReceiverConnectionProvider);
  final rssi = ref.watch(effectiveConnectedRssiProvider);
  return connection == ReceiverConnectionState.connected &&
      rssi != null &&
      rssiToPercent(rssi) < settings.signalThreshold;
});

final controlPageAlertMessageProvider = Provider<String?>((ref) {
  final messages = <String>[
    if (ref.watch(batteryLowAlertVisibleProvider)) AppText.tr('电量低！'),
    if (ref.watch(signalLowAlertVisibleProvider)) AppText.tr('信号低！'),
  ];
  if (messages.isEmpty) {
    return null;
  }
  return messages.join(' ');
});

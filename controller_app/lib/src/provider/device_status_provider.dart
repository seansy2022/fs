import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/receiver_battery_status.dart';
import 'effective_bluetooth_provider.dart';
import 'app_settings_provider.dart';

class DeviceStatusState {
  const DeviceStatusState({
    required this.batteryPercent,
    required this.voltage,
    required this.signalRssi,
    required this.speed,
  });

  const DeviceStatusState.initial()
    : batteryPercent = null,
      voltage = null,
      signalRssi = null,
      speed = null;

  final int? batteryPercent;
  final double? voltage;
  final int? signalRssi;
  final double? speed;
}

final deviceStatusProvider = Provider<DeviceStatusState>((ref) {
  final batteryStatus = ref.watch(receiverBatteryStatusProvider);
  final rssi = ref.watch(effectiveConnectedRssiProvider);
  return DeviceStatusState(
    batteryPercent: batteryStatus?.displayPercent,
    voltage: batteryStatus?.voltage,
    signalRssi: rssi,
    speed: null,
  );
});

/// 根据原始接收机数据与当前设置提供统一的电池状态。
final receiverBatteryStatusProvider = Provider<ReceiverBatteryStatus?>((ref) {
  final rawBatteryLevel = ref
      .watch(effectiveReceiverInfoProvider)
      ?.batteryLevel;
  if (rawBatteryLevel == null) {
    return null;
  }
  final settings = ref.watch(appSettingsProvider);
  return ReceiverBatteryStatus.fromRawBatteryLevel(
    rawBatteryLevel: rawBatteryLevel,
    minimumVoltage: settings.minimumVoltage,
    fullVoltage: settings.fullVoltage,
  );
});

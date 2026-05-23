import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

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
  final info = ref.watch(receiverInfoProvider).valueOrNull;
  final rssi = ref.watch(connectedRssiProvider).valueOrNull;
  return DeviceStatusState(
    batteryPercent: info?.batteryLevel,
    voltage: null,
    signalRssi: rssi,
    speed: null,
  );
});

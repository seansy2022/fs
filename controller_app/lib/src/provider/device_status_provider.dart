import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'effective_bluetooth_provider.dart';
import 'simulated_bluetooth_provider.dart';

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
  final info = ref.watch(effectiveReceiverInfoProvider);
  final rssi = ref.watch(effectiveConnectedRssiProvider);
  final simulated = ref.watch(simulatedBluetoothTelemetryProvider);
  return DeviceStatusState(
    batteryPercent: info?.batteryLevel,
    voltage: simulated?.voltage,
    signalRssi: rssi,
    speed: null,
  );
});

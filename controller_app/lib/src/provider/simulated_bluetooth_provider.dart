import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import 'app_settings_provider.dart';

class SimulatedBluetoothSnapshot {
  const SimulatedBluetoothSnapshot({
    required this.connectionState,
    this.batteryLevel,
    this.voltage,
    this.rssi,
    this.receiverInfo,
  });

  final ReceiverConnectionState connectionState;
  final int? batteryLevel;
  final double? voltage;
  final int? rssi;
  final ReceiverInfo? receiverInfo;
}

final simulatedBluetoothEnabledProvider = Provider<bool>((ref) => true);

final simulatedBluetoothStepDurationProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 5);
});

const _simulatedBatterySteps = <int>[100, 75, 50, 25, 0];
const _simulatedSignalSteps = <int>[-40, -60, -75, -90];

final simulatedBluetoothSnapshotProvider =
    StreamProvider.autoDispose<SimulatedBluetoothSnapshot>((ref) {
      if (!ref.watch(simulatedBluetoothEnabledProvider)) {
        return Stream<SimulatedBluetoothSnapshot>.value(
          const SimulatedBluetoothSnapshot(
            connectionState: ReceiverConnectionState.disconnected,
          ),
        );
      }
      final settings = ref.watch(appSettingsProvider);
      final stepDuration = ref.watch(simulatedBluetoothStepDurationProvider);
      late final StreamController<SimulatedBluetoothSnapshot> controller;
      Timer? timer;
      var index = 0;
      final totalSteps = _simulatedBatterySteps.length + 1;

      void emitNext() {
        final stepIndex = index % totalSteps;
        if (stepIndex == _simulatedBatterySteps.length) {
          controller.add(
            const SimulatedBluetoothSnapshot(
              connectionState: ReceiverConnectionState.disconnected,
            ),
          );
          index++;
          return;
        }
        final batteryLevel = _simulatedBatterySteps[stepIndex];
        final rssi = stepIndex < _simulatedSignalSteps.length
            ? _simulatedSignalSteps[stepIndex]
            : _simulatedSignalSteps.last;
        final voltage = calculateBatteryVoltage(
          batteryPercent: batteryLevel,
          minVoltage: settings.minimumVoltage,
          fullVoltage: settings.fullVoltage,
        );
        controller.add(
          SimulatedBluetoothSnapshot(
            connectionState: ReceiverConnectionState.connected,
            batteryLevel: batteryLevel,
            voltage: voltage,
            rssi: rssi,
            receiverInfo: ReceiverInfo(
              rfmId: Uint8List(4),
              productModelCode: 1,
              batteryLevel: batteryLevel,
              remoteId: 'simulated-receiver',
            ),
          ),
        );
        index++;
      }

      controller = StreamController<SimulatedBluetoothSnapshot>(
        onListen: () {
          emitNext();
          timer = Timer.periodic(stepDuration, (_) => emitNext());
        },
        onCancel: () async {
          timer?.cancel();
        },
      );
      ref.onDispose(() {
        timer?.cancel();
        unawaited(controller.close());
      });
      return controller.stream;
    });

final simulatedBluetoothTelemetryProvider =
    Provider<SimulatedBluetoothSnapshot?>((ref) {
      return ref.watch(simulatedBluetoothSnapshotProvider).valueOrNull;
    });

final simulatedConnectionStateProvider =
    Provider<AsyncValue<ReceiverConnectionState>>((ref) {
      return ref
          .watch(simulatedBluetoothSnapshotProvider)
          .whenData((snapshot) => snapshot.connectionState);
    });

final simulatedReceiverInfoProvider = Provider<AsyncValue<ReceiverInfo?>>((
  ref,
) {
  return ref
      .watch(simulatedBluetoothSnapshotProvider)
      .whenData((snapshot) => snapshot.receiverInfo);
});

final simulatedConnectedRssiProvider = Provider<AsyncValue<int?>>((ref) {
  return ref
      .watch(simulatedBluetoothSnapshotProvider)
      .whenData((snapshot) => snapshot.rssi);
});

int calculateBatteryPercent({
  required double voltage,
  required double minVoltage,
  required double fullVoltage,
}) {
  final span = fullVoltage - minVoltage;
  if (span <= 0) {
    return 0;
  }
  final ratio = ((voltage - minVoltage) / span).clamp(0.0, 1.0);
  return (ratio * 100).round();
}

double calculateBatteryVoltage({
  required int batteryPercent,
  required double minVoltage,
  required double fullVoltage,
}) {
  final span = fullVoltage - minVoltage;
  if (span <= 0) {
    return minVoltage;
  }
  final ratio = (batteryPercent.clamp(0, 100) as int) / 100;
  return minVoltage + span * ratio;
}

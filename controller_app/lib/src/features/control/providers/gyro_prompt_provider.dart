import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../provider/app_settings_provider.dart';
import '../../settings/models/app_settings_state.dart';

class GyroPrompt {
  const GyroPrompt({required this.steering, required this.throttle});

  const GyroPrompt.zero() : steering = 0, throttle = 0;

  final double steering;
  final double throttle;
}

const _maxTiltDegree = 30.0;
const _deadZoneDegree = 2.0;

final gyroPromptProvider = StreamProvider.autoDispose<GyroPrompt>((ref) async* {
  final mode = ref.watch(appSettingsProvider.select((s) => s.gyroMode));
  if (kDebugMode) {
    debugPrint('[gyro-prompt] start mode=${mode.name}');
  }
  if (mode == GyroMode.directionOnly) {
    await for (final event in accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    )) {
      final steering = mapDirectionSteeringFromAccelerometer(
        y: event.y,
        z: event.z,
      );
      yield GyroPrompt(steering: steering, throttle: 0.0);
    }
    return;
  }

  if (mode == GyroMode.throttleOnly) {
    await for (final event in accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    )) {
      final rollDegree = _degree(math.atan2(event.x, event.z));
      final throttle = _mapDegreeToUnit(-rollDegree);
      yield GyroPrompt(steering: 0.0, throttle: throttle);
    }
    return;
  }

  await for (final event in accelerometerEventStream(
    samplingPeriod: SensorInterval.gameInterval,
  )) {
    final rollDegree = _degree(math.atan2(event.x, event.z));
    // In all-mode, left/right tilt controls steering and front/back tilt controls throttle.
    final steering = mapDirectionSteeringFromAccelerometer(
      y: event.y,
      z: event.z,
    );
    final throttle = _mapDegreeToUnit(-rollDegree);
    yield GyroPrompt(steering: steering, throttle: throttle);
  }
});

double _degree(double radians) => radians * 180 / math.pi;

@visibleForTesting
double mapDirectionSteeringFromAccelerometer({
  required double y,
  required double z,
}) {
  final pitchDegree = _degree(math.atan2(y, z));
  return _mapDegreeToUnit(pitchDegree);
}

double _mapDegreeToUnit(double degree) {
  final absValue = degree.abs();
  if (absValue <= _deadZoneDegree) {
    return 0;
  }
  return (degree / _maxTiltDegree).clamp(-1, 1);
}

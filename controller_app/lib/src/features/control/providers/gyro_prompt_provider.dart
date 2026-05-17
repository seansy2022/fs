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
  if (mode == GyroMode.off) {
    yield const GyroPrompt.zero();
    return;
  }
  if (kDebugMode) {
    debugPrint('[gyro-prompt] start mode=${mode.name}');
  }
  if (mode == GyroMode.directionOnly) {
    var sample = 0;
    var headingDegree = 0.0;
    DateTime? lastAt;
    await for (final event in gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    )) {
      final now = event.timestamp;
      final dtSeconds = lastAt == null
          ? 0.0
          : (now.millisecondsSinceEpoch - lastAt.millisecondsSinceEpoch) /
                1000.0;
      lastAt = now;
      final deltaDegree = event.z * dtSeconds * 180 / math.pi;
      headingDegree = (headingDegree + deltaDegree).clamp(
        -_maxTiltDegree,
        _maxTiltDegree,
      );
      final steering = _mapDegreeToUnit(headingDegree);
      sample += 1;
      if (kDebugMode && sample % 8 == 0) {
        debugPrint(
          '[gyro-prompt] gyroZ=${event.z.toStringAsFixed(3)} dt=${dtSeconds.toStringAsFixed(3)} '
          'heading=${headingDegree.toStringAsFixed(1)} out=(${steering.toStringAsFixed(2)},0.00)',
        );
      }
      yield GyroPrompt(steering: steering, throttle: 0.0);
    }
    return;
  }

  var sample = 0;
  await for (final event in accelerometerEventStream(
    samplingPeriod: SensorInterval.gameInterval,
  )) {
    final rollDegree = _degree(math.atan2(event.x, event.z));
    final pitchDegree = _degree(math.atan2(event.y, event.z));
    // In all-mode, left/right tilt controls steering and front/back tilt controls throttle.
    final steering = _mapDegreeToUnit(pitchDegree);
    final throttle = _mapDegreeToUnit(-rollDegree);
    sample += 1;
    if (kDebugMode && sample % 8 == 0) {
      debugPrint(
        '[gyro-prompt] acc=(${event.x.toStringAsFixed(2)},${event.y.toStringAsFixed(2)},${event.z.toStringAsFixed(2)}) '
        'roll=${rollDegree.toStringAsFixed(1)} pitch=${pitchDegree.toStringAsFixed(1)} '
        'out=(${steering.toStringAsFixed(2)},${throttle.toStringAsFixed(2)})',
      );
    }
    yield GyroPrompt(steering: steering, throttle: throttle);
  }
});

double _degree(double radians) => radians * 180 / math.pi;

double _mapDegreeToUnit(double degree) {
  final absValue = degree.abs();
  if (absValue <= _deadZoneDegree) {
    return 0;
  }
  return (degree / _maxTiltDegree).clamp(-1, 1);
}

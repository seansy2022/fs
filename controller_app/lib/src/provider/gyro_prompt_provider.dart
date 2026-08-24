import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'app_settings_provider.dart';
import '../features/settings/models/app_settings_state.dart';
import '../features/settings/models/gyro_calibration_settings.dart';

class GyroPrompt {
  const GyroPrompt({required this.steering, required this.throttle});

  const GyroPrompt.zero() : steering = 0, throttle = 0;

  final double steering;
  final double throttle;
}

const _deadZoneDegree = 2.0;

final gyroPromptProvider = StreamProvider.autoDispose<GyroPrompt>((ref) async* {
  final settings = ref.watch(appSettingsProvider);
  final mode = settings.gyroMode;
  final calibration = settings.gyroCalibration;
  if (kDebugMode) {
    debugPrint('[gyro-prompt] start mode=${mode.name}');
  }
  if (mode == GyroMode.off) {
    yield const GyroPrompt.zero();
    return;
  }

  if (mode == GyroMode.directionOnly) {
    await for (final event in accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    )) {
      final steering = mapDirectionSteeringFromAccelerometer(
        y: event.y,
        z: event.z,
        calibration: calibration,
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
      final throttle = mapThrottleFromDegree(
        degree: -rollDegree,
        calibration: calibration,
      );
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
      calibration: calibration,
    );
    final throttle = mapThrottleFromDegree(
      degree: -rollDegree,
      calibration: calibration,
    );
    yield GyroPrompt(steering: steering, throttle: throttle);
  }
});

double _degree(double radians) => radians * 180 / math.pi;

@visibleForTesting
double mapDirectionSteeringFromAccelerometer({
  required double y,
  required double z,
  GyroCalibrationSettings calibration = GyroCalibrationSettings.defaults,
}) {
  final pitchDegree = _degree(math.atan2(y, z));
  return mapSteeringFromDegree(degree: pitchDegree, calibration: calibration);
}

/// 依据保存的油门校准点，将手机角度转换成 -1～1 的油门输入。
@visibleForTesting
double mapThrottleFromDegree({
  required double degree,
  required GyroCalibrationSettings calibration,
}) {
  return _mapCalibratedDegree(
    degree: degree,
    positiveDegree: calibration.throttleForwardDegree,
    centerDegree: calibration.throttleCenterDegree,
    negativeDegree: calibration.throttleReverseDegree,
  );
}

/// 依据保存的方向校准点，将手机角度转换成 -1～1 的方向输入。
@visibleForTesting
double mapSteeringFromDegree({
  required double degree,
  required GyroCalibrationSettings calibration,
}) {
  return _mapCalibratedDegree(
    degree: degree,
    positiveDegree: calibration.steeringLeftDegree,
    centerDegree: calibration.steeringCenterDegree,
    negativeDegree: calibration.steeringRightDegree,
  );
}

/// 以居中角度为零点，对正负两个校准区间分别做线性映射。
double _mapCalibratedDegree({
  required double degree,
  required double positiveDegree,
  required double centerDegree,
  required double negativeDegree,
}) {
  final offset = degree - centerDegree;
  if (offset.abs() <= _deadZoneDegree) {
    return 0;
  }
  if (offset > 0) {
    return (offset / (positiveDegree - centerDegree)).clamp(0, 1);
  }
  return (offset / (centerDegree - negativeDegree)).clamp(-1, 0);
}

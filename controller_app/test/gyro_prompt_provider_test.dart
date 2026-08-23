import 'dart:math' as math;

import 'package:controller_app/src/features/settings/models/gyro_calibration_settings.dart';
import 'package:controller_app/src/provider/gyro_prompt_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('direction steering mapping is symmetric for left/right tilt', () {
    final rightSteering = mapDirectionSteeringFromAccelerometer(
      y: math.tan(_radians(15)),
      z: 1,
    );
    final leftSteering = mapDirectionSteeringFromAccelerometer(
      y: math.tan(_radians(-15)),
      z: 1,
    );

    expect(rightSteering, closeTo(1 / 3, 0.0001));
    expect(leftSteering, closeTo(-1 / 3, 0.0001));
    expect(rightSteering, closeTo(-leftSteering, 0.0001));
  });

  test(
    'direction steering mapping keeps dead zone at and within 2 degrees',
    () {
      expect(mapDirectionSteeringFromAccelerometer(y: 0, z: 1), equals(0));
      expect(
        mapDirectionSteeringFromAccelerometer(y: math.tan(_radians(2)), z: 1),
        equals(0),
      );
      expect(
        mapDirectionSteeringFromAccelerometer(y: math.tan(_radians(-2)), z: 1),
        equals(0),
      );
    },
  );

  test(
    'direction steering mapping clamps beyond calibrated plus/minus 45 degrees',
    () {
      expect(
        mapDirectionSteeringFromAccelerometer(y: math.tan(_radians(45)), z: 1),
        equals(1),
      );
      expect(
        mapDirectionSteeringFromAccelerometer(y: math.tan(_radians(-45)), z: 1),
        equals(-1),
      );
    },
  );

  test('custom calibration uses the saved center and limits', () {
    const calibration = GyroCalibrationSettings(
      throttleForwardDegree: 60,
      throttleCenterDegree: 10,
      throttleReverseDegree: -30,
      steeringLeftDegree: 30,
      steeringCenterDegree: -10,
      steeringRightDegree: -50,
    );

    expect(
      mapThrottleFromDegree(degree: 35, calibration: calibration),
      closeTo(0.5, 0.0001),
    );
    expect(
      mapThrottleFromDegree(degree: -10, calibration: calibration),
      closeTo(-0.5, 0.0001),
    );
    expect(
      mapSteeringFromDegree(degree: 10, calibration: calibration),
      closeTo(0.5, 0.0001),
    );
  });

  test('six calibration points map to zero and endpoint outputs', () {
    const calibration = GyroCalibrationSettings(
      throttleForwardDegree: 60,
      throttleCenterDegree: 12,
      throttleReverseDegree: -36,
      steeringLeftDegree: 42,
      steeringCenterDegree: -8,
      steeringRightDegree: -52,
    );

    // 油门零位、前进最大值和后退最大值分别对应 0%、+100% 和 -100%。
    expect(mapThrottleFromDegree(degree: 12, calibration: calibration), 0);
    expect(mapThrottleFromDegree(degree: 60, calibration: calibration), 1);
    expect(mapThrottleFromDegree(degree: -36, calibration: calibration), -1);

    // 方向零位、左转最大值和右转最大值遵循相同的端点规则。
    expect(mapSteeringFromDegree(degree: -8, calibration: calibration), 0);
    expect(mapSteeringFromDegree(degree: 42, calibration: calibration), 1);
    expect(mapSteeringFromDegree(degree: -52, calibration: calibration), -1);
  });
}

double _radians(double degree) => degree * math.pi / 180;

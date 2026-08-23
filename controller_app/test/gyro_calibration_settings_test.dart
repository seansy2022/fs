import 'package:controller_app/src/features/settings/models/gyro_calibration_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default gyro calibration is valid', () {
    expect(GyroCalibrationSettings.defaults.isValid, isTrue);
  });

  test('invalid calibration rejects wrong range and point order', () {
    const invalidRange = GyroCalibrationSettings(
      throttleForwardDegree: -1,
      throttleCenterDegree: 0,
      throttleReverseDegree: -45,
      steeringLeftDegree: 45,
      steeringCenterDegree: 0,
      steeringRightDegree: -45,
    );
    const invalidOrder = GyroCalibrationSettings(
      throttleForwardDegree: 45,
      throttleCenterDegree: 50,
      throttleReverseDegree: -45,
      steeringLeftDegree: 45,
      steeringCenterDegree: 0,
      steeringRightDegree: -45,
    );

    expect(invalidRange.isValid, isFalse);
    expect(invalidOrder.isValid, isFalse);
  });

  test('invalid stored calibration safely restores defaults', () {
    final result = GyroCalibrationSettings.fromJson(<String, Object?>{
      'throttleForwardDegree': 10,
      'throttleCenterDegree': 20,
      'throttleReverseDegree': -10,
    });

    expect(result.throttleForwardDegree, 45);
    expect(result.steeringRightDegree, -45);
  });
}

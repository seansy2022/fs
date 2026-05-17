import 'dart:math' as math;

import 'package:controller_app/src/features/control/providers/gyro_prompt_provider.dart';
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

    expect(rightSteering, closeTo(0.5, 0.0001));
    expect(leftSteering, closeTo(-0.5, 0.0001));
    expect(rightSteering, closeTo(-leftSteering, 0.0001));
  });

  test('direction steering mapping keeps dead zone at and within 2 degrees', () {
    expect(
      mapDirectionSteeringFromAccelerometer(y: 0, z: 1),
      equals(0),
    );
    expect(
      mapDirectionSteeringFromAccelerometer(y: math.tan(_radians(2)), z: 1),
      equals(0),
    );
    expect(
      mapDirectionSteeringFromAccelerometer(y: math.tan(_radians(-2)), z: 1),
      equals(0),
    );
  });

  test('direction steering mapping clamps beyond plus/minus 30 degrees', () {
    expect(
      mapDirectionSteeringFromAccelerometer(y: math.tan(_radians(45)), z: 1),
      equals(1),
    );
    expect(
      mapDirectionSteeringFromAccelerometer(y: math.tan(_radians(-45)), z: 1),
      equals(-1),
    );
  });
}

double _radians(double degree) => degree * math.pi / 180;

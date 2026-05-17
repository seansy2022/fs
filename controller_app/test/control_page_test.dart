import 'package:controller_app/src/features/control/pages/control_page.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gyro override stays off when control-page gyro switch is off', () {
    expect(
      shouldUseGyroControlOverride(
        gyroEnabled: false,
        gyroMode: GyroMode.directionOnly,
      ),
      isFalse,
    );
    expect(
      shouldUseGyroControlOverride(
        gyroEnabled: false,
        gyroMode: GyroMode.throttleOnly,
      ),
      isFalse,
    );
  });

  test('gyro override only applies for enabled single-axis gyro modes', () {
    expect(
      shouldUseGyroControlOverride(
        gyroEnabled: true,
        gyroMode: GyroMode.directionOnly,
      ),
      isTrue,
    );
    expect(
      shouldUseGyroControlOverride(
        gyroEnabled: true,
        gyroMode: GyroMode.throttleOnly,
      ),
      isTrue,
    );
    expect(
      shouldUseGyroControlOverride(gyroEnabled: true, gyroMode: GyroMode.all),
      isFalse,
    );
  });
}

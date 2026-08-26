import 'package:controller_app/src/features/control/controllers/control_layout_policy.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('未启用体感时单手手型选择二维布局', () {
    expect(
      resolveControlLayout(
        gyroEnabled: false,
        handedness: Handedness.singleLeft,
        gyroMode: GyroMode.all,
      ),
      ControlLayoutKind.manualSingle,
    );
  });

  test('未启用体感时双手手型选择双控布局', () {
    expect(
      resolveControlLayout(
        gyroEnabled: false,
        handedness: Handedness.rightThrottle,
        gyroMode: GyroMode.all,
      ),
      ControlLayoutKind.manualDual,
    );
  });

  test('体感布局覆盖三个体感类型', () {
    for (final mode in GyroMode.values) {
      expect(
        resolveControlLayout(
          gyroEnabled: true,
          handedness: Handedness.singleRight,
          gyroMode: mode,
        ),
        switch (mode) {
          GyroMode.directionOnly => ControlLayoutKind.gyroDirection,
          GyroMode.throttleOnly => ControlLayoutKind.gyroThrottle,
          GyroMode.all => ControlLayoutKind.none,
        },
      );
    }
  });

  test('操控模式准确决定是否使用隐藏可变控件', () {
    expect(usesFloatingControl(ControlMode.fixedPosition), isFalse);
    expect(usesFloatingControl(ControlMode.floating), isTrue);
  });
}

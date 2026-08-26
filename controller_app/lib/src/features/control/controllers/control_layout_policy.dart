import '../../settings/models/app_settings_state.dart';

/// 控制页触控主控的布局类型。
enum ControlLayoutKind {
  manualDual,
  manualSingle,
  gyroDirection,
  gyroThrottle,
  none,
}

/// 将设置组合归一为控制页所需的主控布局，供页面组装与单元测试共用。
ControlLayoutKind resolveControlLayout({
  required bool gyroEnabled,
  required Handedness handedness,
  required GyroMode gyroMode,
}) {
  // 陀螺仪关闭时始终使用基本手型；单手布局需要二维控制区。
  if (!gyroEnabled) {
    return handedness == Handedness.singleLeft ||
            handedness == Handedness.singleRight
        ? ControlLayoutKind.manualSingle
        : ControlLayoutKind.manualDual;
  }
  return switch (gyroMode) {
    GyroMode.directionOnly => ControlLayoutKind.gyroDirection,
    GyroMode.throttleOnly => ControlLayoutKind.gyroThrottle,
    GyroMode.all => ControlLayoutKind.none,
  };
}

/// 判断当前操控模式是否需要使用按下显示、松手隐藏的可变位置控件。
bool usesFloatingControl(ControlMode controlMode) {
  return controlMode == ControlMode.floating;
}

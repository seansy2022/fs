/// 体感油门与方向的角度校准配置。
///
/// 正方向使用 0～90°，负方向使用 -90～0°；居中点允许偏移，
/// 以适配不同用户握持手机时的自然水平姿势。
class GyroCalibrationSettings {
  const GyroCalibrationSettings({
    required this.throttleForwardDegree,
    required this.throttleCenterDegree,
    required this.throttleReverseDegree,
    required this.steeringLeftDegree,
    required this.steeringCenterDegree,
    required this.steeringRightDegree,
  });

  static const defaults = GyroCalibrationSettings(
    throttleForwardDegree: 45,
    throttleCenterDegree: 0,
    throttleReverseDegree: -45,
    steeringLeftDegree: 45,
    steeringCenterDegree: 0,
    steeringRightDegree: -45,
  );

  final double throttleForwardDegree;
  final double throttleCenterDegree;
  final double throttleReverseDegree;
  final double steeringLeftDegree;
  final double steeringCenterDegree;
  final double steeringRightDegree;

  /// 是否满足输入范围与三个校准点从正向到负向的排列关系。
  bool get isValid =>
      _isAxisValid(
        positive: throttleForwardDegree,
        center: throttleCenterDegree,
        negative: throttleReverseDegree,
      ) &&
      _isAxisValid(
        positive: steeringLeftDegree,
        center: steeringCenterDegree,
        negative: steeringRightDegree,
      );

  GyroCalibrationSettings copyWith({
    double? throttleForwardDegree,
    double? throttleCenterDegree,
    double? throttleReverseDegree,
    double? steeringLeftDegree,
    double? steeringCenterDegree,
    double? steeringRightDegree,
  }) {
    return GyroCalibrationSettings(
      throttleForwardDegree:
          throttleForwardDegree ?? this.throttleForwardDegree,
      throttleCenterDegree: throttleCenterDegree ?? this.throttleCenterDegree,
      throttleReverseDegree:
          throttleReverseDegree ?? this.throttleReverseDegree,
      steeringLeftDegree: steeringLeftDegree ?? this.steeringLeftDegree,
      steeringCenterDegree: steeringCenterDegree ?? this.steeringCenterDegree,
      steeringRightDegree: steeringRightDegree ?? this.steeringRightDegree,
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'throttleForwardDegree': throttleForwardDegree,
      'throttleCenterDegree': throttleCenterDegree,
      'throttleReverseDegree': throttleReverseDegree,
      'steeringLeftDegree': steeringLeftDegree,
      'steeringCenterDegree': steeringCenterDegree,
      'steeringRightDegree': steeringRightDegree,
    };
  }

  /// 兼容旧版本没有体感校准字段的已保存设置。
  factory GyroCalibrationSettings.fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) {
      return defaults;
    }
    final value = GyroCalibrationSettings(
      throttleForwardDegree:
          (raw['throttleForwardDegree'] as num?)?.toDouble() ?? 45,
      throttleCenterDegree:
          (raw['throttleCenterDegree'] as num?)?.toDouble() ?? 0,
      throttleReverseDegree:
          (raw['throttleReverseDegree'] as num?)?.toDouble() ?? -45,
      steeringLeftDegree: (raw['steeringLeftDegree'] as num?)?.toDouble() ?? 45,
      steeringCenterDegree:
          (raw['steeringCenterDegree'] as num?)?.toDouble() ?? 0,
      steeringRightDegree:
          (raw['steeringRightDegree'] as num?)?.toDouble() ?? -45,
    );
    return value.isValid ? value : defaults;
  }

  static bool _isAxisValid({
    required double positive,
    required double center,
    required double negative,
  }) {
    return positive >= 0 &&
        positive <= 90 &&
        center >= -90 &&
        center <= 90 &&
        negative >= -90 &&
        negative <= 0 &&
        positive > center &&
        center > negative;
  }
}

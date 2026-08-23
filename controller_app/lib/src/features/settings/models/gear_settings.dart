/// 控制页高低挡的前进、后退比例配置。
class GearSettings {
  const GearSettings({
    required this.lowReversePercent,
    required this.lowForwardPercent,
    required this.highReversePercent,
    required this.highForwardPercent,
  });

  /// 保持当前 App 的既有控制行为：低速仅限制前进到 50%。
  static const defaults = GearSettings(
    lowReversePercent: 100,
    lowForwardPercent: 50,
    highReversePercent: 100,
    highForwardPercent: 100,
  );

  final double lowReversePercent;
  final double lowForwardPercent;
  final double highReversePercent;
  final double highForwardPercent;

  /// 返回替换指定比例后的不可变配置。
  GearSettings copyWith({
    double? lowReversePercent,
    double? lowForwardPercent,
    double? highReversePercent,
    double? highForwardPercent,
  }) {
    return GearSettings(
      lowReversePercent: lowReversePercent ?? this.lowReversePercent,
      lowForwardPercent: lowForwardPercent ?? this.lowForwardPercent,
      highReversePercent: highReversePercent ?? this.highReversePercent,
      highForwardPercent: highForwardPercent ?? this.highForwardPercent,
    );
  }

  /// 将配置转为本地持久化格式。
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'lowReversePercent': lowReversePercent,
      'lowForwardPercent': lowForwardPercent,
      'highReversePercent': highReversePercent,
      'highForwardPercent': highForwardPercent,
    };
  }

  /// 读取本地配置；旧版本数据缺失时保持既有 App 的默认控制行为。
  factory GearSettings.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return GearSettings.defaults;
    }
    return GearSettings(
      lowReversePercent: _percent(json['lowReversePercent'], 100),
      lowForwardPercent: _percent(json['lowForwardPercent'], 50),
      highReversePercent: _percent(json['highReversePercent'], 100),
      highForwardPercent: _percent(json['highForwardPercent'], 100),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GearSettings &&
        other.lowReversePercent == lowReversePercent &&
        other.lowForwardPercent == lowForwardPercent &&
        other.highReversePercent == highReversePercent &&
        other.highForwardPercent == highForwardPercent;
  }

  @override
  int get hashCode => Object.hash(
    lowReversePercent,
    lowForwardPercent,
    highReversePercent,
    highForwardPercent,
  );
}

/// 限制挡位比例在 0%–100%，防止本地脏数据影响控制输出。
double normalizeGearPercent(num value) => value.clamp(0, 100).toDouble();

/// 根据当前挡位和油门方向应用前进或后退比例。
double applyGearThrottleRatio({
  required double throttle,
  required bool highGear,
  required GearSettings settings,
}) {
  final ratio = highGear
      ? (throttle < 0
            ? settings.highReversePercent
            : settings.highForwardPercent)
      : (throttle < 0
            ? settings.lowReversePercent
            : settings.lowForwardPercent);
  return throttle * (ratio / 100);
}

double _percent(Object? value, double fallback) {
  return value is num ? normalizeGearPercent(value) : fallback;
}

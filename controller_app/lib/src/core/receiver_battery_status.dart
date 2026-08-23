/// 接收机电量的统一换算结果。
///
/// 接收机协议中的原始值固定按 3.5V 到 8.5V 映射；界面电量和报警
/// 则使用用户在设置页配置的最低、满电电压重新计算。
class ReceiverBatteryStatus {
  const ReceiverBatteryStatus._({
    required this.rawPercent,
    required this.voltage,
    required this.percent,
  });

  static const double rawMinimumVoltage = 3.5;
  static const double rawFullVoltage = 8.5;
  static const int iconLevelCount = 5;

  final int rawPercent;
  final double voltage;
  final double percent;

  /// 将接收机原始电量与当前电压设置换算为可展示的电池状态。
  factory ReceiverBatteryStatus.fromRawBatteryLevel({
    required int rawBatteryLevel,
    required double minimumVoltage,
    required double fullVoltage,
  }) {
    final rawPercent = rawBatteryLevel.clamp(0, 100);
    final voltage = voltageFromRawPercent(rawPercent);
    return ReceiverBatteryStatus._(
      rawPercent: rawPercent,
      voltage: voltage,
      percent: percentFromVoltage(
        voltage: voltage,
        minimumVoltage: minimumVoltage,
        fullVoltage: fullVoltage,
      ),
    );
  }

  /// 将协议原始百分比按固定标定区间换算为真实电压。
  static double voltageFromRawPercent(int rawBatteryLevel) {
    final rawPercent = rawBatteryLevel.clamp(0, 100);
    final ratio = rawPercent / 100;
    return rawMinimumVoltage + (rawFullVoltage - rawMinimumVoltage) * ratio;
  }

  /// 按设置页的最低与满电电压换算展示百分比，并保护异常配置。
  static double percentFromVoltage({
    required double voltage,
    required double minimumVoltage,
    required double fullVoltage,
  }) {
    final span = fullVoltage - minimumVoltage;
    if (span <= 0) {
      return 0;
    }
    return ((voltage - minimumVoltage) / span * 100).clamp(0.0, 100.0);
  }

  /// 首页等文字展示使用四舍五入后的完整百分比。
  int get displayPercent => percent.round();

  /// 电池图标使用五个等分档位，最低电压时显示为空。
  int get iconPercent {
    final level = (percent / (100 / iconLevelCount)).ceil().clamp(
      0,
      iconLevelCount,
    );
    return level * (100 ~/ iconLevelCount);
  }

  /// 电量到达报警阈值时应立即告警。
  bool isAtOrBelow(double thresholdPercent) => percent <= thresholdPercent;
}

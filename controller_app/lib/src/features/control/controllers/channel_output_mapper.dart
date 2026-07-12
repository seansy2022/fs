class PrimaryChannelCalibration {
  const PrimaryChannelCalibration({
    required this.lowUs,
    required this.centerUs,
    required this.highUs,
  });

  final int lowUs;
  final int centerUs;
  final int highUs;

  int clamp(int value) => value.clamp(lowUs, highUs);
}

/// 计算主通道的范围和中位偏移后的三点输出。
PrimaryChannelCalibration calibratePrimaryChannel({
  required double lowPercent,
  required double centerOffsetUs,
  required double highPercent,
}) {
  final lowBound = (1500 + (lowPercent * 5)).round().clamp(900, 1500);
  final highBound = (1500 + (highPercent * 5)).round().clamp(1500, 2100);
  final offset = centerOffsetUs.round().clamp(-100, 100);
  return PrimaryChannelCalibration(
    lowUs: (lowBound + offset).clamp(lowBound, highBound),
    centerUs: (1500 + offset).clamp(lowBound, highBound),
    highUs: (highBound + offset).clamp(lowBound, highBound),
  );
}

int channelPercentToUs(double percentSetting) {
  return (1500 + (percentSetting * 5)).round().clamp(900, 2100);
}

/// 将辅助通道百分比转换为 PWM 输出，支持扩展到 ±120%。
int auxChannelPercentToUs(double percentSetting) {
  return (1500 + (percentSetting * 5)).round().clamp(900, 2100);
}

int mapControlInputToUs({
  required double input,
  required double lowPercent,
  required double centerPercent,
  required double highPercent,
}) {
  final calibration = calibratePrimaryChannel(
    lowPercent: lowPercent,
    centerOffsetUs: centerPercent,
    highPercent: highPercent,
  );
  final safeInput = input.clamp(-1.0, 1.0).toDouble();

  final output = safeInput <= 0
      ? calibration.centerUs +
            ((calibration.centerUs - calibration.lowUs) * safeInput)
      : calibration.centerUs +
            ((calibration.highUs - calibration.centerUs) * safeInput);

  return calibration.clamp(output.round());
}

int mapSteeringInputToUs({
  required double steering,
  required double lowPercent,
  required double centerPercent,
  required double highPercent,
  required int trimStep,
}) {
  final mapped = mapControlInputToUs(
    input: steering,
    lowPercent: lowPercent,
    centerPercent: centerPercent,
    highPercent: highPercent,
  );
  return (mapped + (trimStep * 2)).clamp(1000, 2000);
}

int mapThrottleInputToUs({
  required double throttle,
  required double lowPercent,
  required double centerPercent,
  required double highPercent,
}) {
  return mapControlInputToUs(
    input: throttle,
    lowPercent: lowPercent,
    centerPercent: centerPercent,
    highPercent: highPercent,
  );
}

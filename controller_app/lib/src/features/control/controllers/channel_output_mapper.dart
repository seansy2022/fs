int channelPercentToUs(double percentSetting) {
  return (1500 + (percentSetting * 5)).round().clamp(1000, 2000);
}

int mapControlInputToUs({
  required double input,
  required double lowPercent,
  required double centerPercent,
  required double highPercent,
}) {
  final lowUs = channelPercentToUs(lowPercent);
  final centerUs = channelPercentToUs(centerPercent);
  final highUs = channelPercentToUs(highPercent);
  final safeInput = input.clamp(-1.0, 1.0).toDouble();

  final output = safeInput <= 0
      ? centerUs + ((centerUs - lowUs) * safeInput)
      : centerUs + ((highUs - centerUs) * safeInput);

  return output.round().clamp(1000, 2000);
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
    input: -throttle,
    lowPercent: lowPercent,
    centerPercent: centerPercent,
    highPercent: highPercent,
  );
}

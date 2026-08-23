/// 失控保护协议固定值的中位 PWM。
const failsafeCenterUs = 1500;

/// 失控保护页面允许输入的百分比范围。
const failsafePercentLimit = 120;

/// 将接收机协议值转换为页面显示的百分比。
///
/// 协议以 1500us 为中位，每 1% 对应 5us；范围 -120% 到 +120%
/// 恰好对应接收机允许的 900us 到 2100us。
int failsafeUsToPercent(int valueUs) {
  final percent = ((valueUs - failsafeCenterUs) / 5).round();
  return percent.clamp(-failsafePercentLimit, failsafePercentLimit).toInt();
}

/// 将页面输入的百分比转换为接收机协议所需的 PWM 微秒值。
int failsafePercentToUs(int percent) {
  final normalized = percent
      .clamp(-failsafePercentLimit, failsafePercentLimit)
      .toInt();
  return failsafeCenterUs + normalized * 5;
}

const _minimumRssi = -100;
const _maximumRssi = -65;

/// 将 RSSI 线性换算成 0～100 的信号百分比。
///
/// -100dBm 对应 0%，-65dBm 对应 100%；超出范围的值固定在边界，
/// 使控制页显示和低信号报警使用完全一致的信号含义。
int rssiToPercent(int? rssi) {
  if (rssi == null || rssi <= _minimumRssi) {
    return 0;
  }
  if (rssi >= _maximumRssi) {
    return 100;
  }
  return ((rssi - _minimumRssi) / (_maximumRssi - _minimumRssi) * 100).round();
}

/// 返回控制页信号组件使用的线性百分比。
///
/// 保留该方法避免控制页依赖换算细节；[SignalWidget] 会依 25% 切分为四格。
int rssiToControlSignalPercent(int? rssi) {
  return rssiToPercent(rssi);
}

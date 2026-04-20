const controlMappingSwitchActionCodeConfig = <String, int>{
  '四轮转向开关': 11,
  '履带混控开关': 12,
  '驱动混控开关': 13,
  '刹车混控开关': 14,
  '四轮转向模式切换': 12,
  '履带混控切换': 16,
  '驱动混控切换': 14,
  '刹车混控切换': 18,
};

final controlMappingSwitchActionByCodeConfig = <int, String>{
  for (final entry in controlMappingSwitchActionCodeConfig.entries)
    entry.value: entry.key,
};

int? controlMappingSwitchActionCode(String action) {
  return controlMappingSwitchActionCodeConfig[action];
}

String? controlMappingSwitchActionByCode(int code) {
  return controlMappingSwitchActionByCodeConfig[code];
}

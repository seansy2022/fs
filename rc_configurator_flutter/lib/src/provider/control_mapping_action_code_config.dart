const controlMappingSwitchActionCodeConfig = <String, int>{
  '4WS Switch': 11,
  'Track Mix Switch': 12,
  'Drive Mix Switch': 13,
  'Brake Mix Switch': 14,
  '4WS Mode Switch': 11,
  'Track Mix Toggle': 16,
  'Drive Mix Toggle': 13,
  'Brake Mix Toggle': 18,
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

import 'dart:ui' show Locale;

class ControlMappingLabels {
  ControlMappingLabels._();

  static const _zhLabels = <String, String>{
    // Types
    'Click': '单击',
    'Double Click': '双击',
    'Triple Click': '三击',
    'Long Press': '长按',
    'Knob': '旋钮',
    '3-Pos Switch': '三档开关',
    '3-Pos': '三档',
    '2-Pos': '二档',

    // Modes
    'Flip': '翻转',
    'Trigger': '触发',

    // Common actions
    'None': '无',
    'Channel Output': '通道输出',
    'Mix Function Switch': '混控功能切换',

    // Mixing modes
    '4WS': '四轮转向',
    'Track Mix': '履带混控',
    'Drive Mix': '驱动混控',
    'Brake Mix': '刹车混控',
    '4W Mix': '四轮混控',

    // Mixing functions
    '4W': '四轮',
    'Hybrid': '混动',

    // 4WS direction options
    '4WS Front': '四轮转向前面',
    '4WS Rear': '四轮转向后面',
    '4WS F/R Same': '四轮转向前后同向',
    '4WS F/R Reverse': '四轮转向前后反向',

    // Drive Mix direction options
    'Drive Mix Front': '驱动混控前面',
    'Drive Mix Rear': '驱动混控后面',
    'Drive Mix F/R Hybrid': '驱动混控前后混控',

    // Switch actions
    '4WS Switch': '四轮转向开关',
    'Track Mix Switch': '履带混控开关',
    'Drive Mix Switch': '驱动混控开关',
    'Brake Mix Switch': '刹车混控开关',
    '4WS Mode Switch': '四轮转向模式切换',
    'Track Mix Toggle': '履带混控切换',
    'Drive Mix Toggle': '驱动混控切换',
    'Brake Mix Toggle': '刹车混控切换',

    // Trim actions
    'Steering Trim': '方向微调',
    'Steering Normal Trim': '方向普通微调',
    'Throttle Trim': '油门微调',
    'Throttle Normal Trim': '油门普通微调',

    // Ratio actions
    'Steering Ratio': '方向比率',
    'Forward Ratio': '前进比率',
    'Brake Ratio': '刹车比率',
    '4WS Mix Ratio': '四轮转向混控比率',
    'Drive Mix Forward Ratio': '驱动混控前进比率',
    'Drive Mix Reverse Ratio': '驱动混控后退比率',
    'Brake Mix Ratio': '刹车混控比率',

    // Drive mode options (rc_ui)
    'Front Drive': '前驱',
    'Rear Drive': '后驱',
    'F/R Hybrid': '前后混驱',

    // Tank control
    'Left': '左转',
    'Forward': '前进',
    'Backward': '后退',
    'Right': '右转',

    // Other
    'Mix Channel': '混控通道',
    'Mix Ratio': '混控比率',
    'Mix Curve': '混控曲线',
    'Low Speed': '低速',
    'High Speed': '高速',
    'Searching': '搜索中',
    'Connected': '已连接',
    'Disconnected': '未连接',
    'Device Connected': '设备已连接',
    'Device Disconnected': '设备未连接',
    'Cancel': '取消',
    'OK': '确定',
  };

  /// Returns internal IDs for all Chinese display labels (reverse lookup).
  static final Map<String, String> _idByZh = _zhLabels.map((k, v) => MapEntry(v, k));

  /// Returns the localized display label for [value] based on [locale].
  static String displayLabel(String value, Locale locale) {
    if (locale.languageCode == 'zh') {
      return _zhLabels[value] ?? value;
    }
    return value;
  }

  /// Converts a localized display label back to the internal ID.
  /// Needed when the user selects a Chinese option from a sheet.
  static String internalId(String displayText, Locale locale) {
    if (locale.languageCode == 'zh') {
      return _idByZh[displayText] ?? displayText;
    }
    return displayText;
  }

  /// Returns localized display labels for a list of internal IDs.
  static List<String> displayLabels(List<String> values, Locale locale) {
    return values.map((v) => displayLabel(v, locale)).toList();
  }
}

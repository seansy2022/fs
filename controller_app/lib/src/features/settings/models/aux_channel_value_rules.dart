const int auxChannelPercentMin = -120;
const int auxChannelPercentMax = 120;
const int auxMultiStateMinCount = 3;
const int auxMultiStateMaxCount = 5;
const List<double> defaultAuxSwitchValues = <double>[100, -100];
const List<double> defaultAuxMultiStateValues = <double>[-100, 0, 100];

/// 将辅助通道百分比限制在接收机允许配置的范围内。
double normalizeAuxChannelPercent(num value) {
  return value.clamp(auxChannelPercentMin, auxChannelPercentMax).toDouble();
}

/// 补齐并限制开关通道的开/关两个输出值。
List<double> normalizeAuxSwitchValues(List<double> values) {
  final next = List<double>.generate(2, (index) {
    if (index < values.length) {
      return normalizeAuxChannelPercent(values[index]);
    }
    return defaultAuxSwitchValues[index];
  }, growable: false);
  return next;
}

/// 将多状态通道规范为 3 到 5 个可编辑输出点。
List<double> normalizeAuxMultiStateValues(List<double> values) {
  final source = values.isEmpty ? defaultAuxMultiStateValues : values;
  final next = source
      .take(auxMultiStateMaxCount)
      .map(normalizeAuxChannelPercent)
      .toList(growable: true);
  while (next.length < auxMultiStateMinCount) {
    next.add(defaultAuxMultiStateValues[next.length]);
  }
  return next;
}

/// 更新一个多状态输出点，同时保持值域和状态数量合法。
List<double> updateAuxMultiStateValue(
  List<double> values,
  int index,
  num value,
) {
  final next = normalizeAuxMultiStateValues(values);
  if (index < 0 || index >= next.length) {
    return next;
  }
  next[index] = normalizeAuxChannelPercent(value);
  return next;
}

/// 新增一个多状态输出点，最多保留 5 个状态。
List<double> addAuxMultiStateValue(List<double> values) {
  final next = normalizeAuxMultiStateValues(values);
  if (next.length >= auxMultiStateMaxCount) {
    return next;
  }
  return <double>[...next, 0];
}

/// 删除最后一个多状态输出点，至少保留 3 个状态。
List<double> removeAuxMultiStateValue(List<double> values) {
  final next = normalizeAuxMultiStateValues(values);
  if (next.length <= auxMultiStateMinCount) {
    return next;
  }
  return next..removeLast();
}

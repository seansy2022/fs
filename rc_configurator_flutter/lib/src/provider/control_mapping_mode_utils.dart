List<String> normalizeDistinctModes(
  List<String?> currentModes,
  List<String> options, {
  int? preferredIndex,
  String? preferredValue,
}) {
  final result = List<String?>.filled(3, null);
  if (preferredIndex != null &&
      preferredValue != null &&
      preferredIndex >= 0 &&
      preferredIndex < 3 &&
      options.contains(preferredValue)) {
    result[preferredIndex] = preferredValue;
  }
  final used = result.whereType<String>().toSet();
  for (var i = 0; i < 3; i++) {
    final candidate = i < currentModes.length ? currentModes[i] : null;
    if (result[i] != null || candidate == null) continue;
    if (options.contains(candidate) && !used.contains(candidate)) {
      result[i] = candidate;
      used.add(candidate);
    }
  }
  for (var i = 0; i < 3; i++) {
    if (result[i] != null) continue;
    result[i] = options.firstWhere((item) => !used.contains(item));
    used.add(result[i]!);
  }
  return result.cast<String>();
}

List<String> availableDistinctModes(
  List<String> options,
  List<String?> currentModes,
  int slotIndex,
) {
  final selected = slotIndex < currentModes.length
      ? currentModes[slotIndex]
      : null;
  final occupied = <String>{};
  for (var i = 0; i < currentModes.length; i++) {
    if (i == slotIndex) continue;
    final value = currentModes[i];
    if (value != null && options.contains(value)) occupied.add(value);
  }
  return options
      .where((item) => item == selected || !occupied.contains(item))
      .toList();
}

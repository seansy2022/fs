import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoredAuxChannelRuntime {
  const StoredAuxChannelRuntime({
    this.selectedIndex = 0,
    this.switchOn = false,
  });

  final int selectedIndex;
  final bool switchOn;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'selectedIndex': selectedIndex,
      'switchOn': switchOn,
    };
  }

  factory StoredAuxChannelRuntime.fromJson(Map<String, Object?> json) {
    return StoredAuxChannelRuntime(
      selectedIndex: (json['selectedIndex'] as num?)?.toInt() ?? 0,
      switchOn: json['switchOn'] as bool? ?? false,
    );
  }
}

class ControlAuxRuntimeStore {
  static const _storageKey = 'controller_app.control_aux_runtime.v1';

  /// 读取控制页 CH3/CH4 辅助通道的上次选择状态。
  Future<Map<int, StoredAuxChannelRuntime>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const <int, StoredAuxChannelRuntime>{};
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) {
        return MapEntry(
          int.parse(key),
          StoredAuxChannelRuntime.fromJson(
            Map<String, Object?>.from(value as Map),
          ),
        );
      });
    } catch (_) {
      return const <int, StoredAuxChannelRuntime>{};
    }
  }

  /// 保存单个辅助通道状态，避免覆盖另一通道的记录。
  Future<void> saveChannel(
    int channelIndex,
    StoredAuxChannelRuntime runtime,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final values = await load();
    final next = <String, Object?>{
      for (final entry in values.entries) '${entry.key}': entry.value.toJson(),
      '$channelIndex': runtime.toJson(),
    };
    await prefs.setString(_storageKey, jsonEncode(next));
  }
}

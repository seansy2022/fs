import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 控制页输入操作的可恢复状态。
class StoredControlInputState {
  const StoredControlInputState({
    this.gyroEnabled = false,
    this.throttleTrim = 0,
    this.steeringTrim = 0,
    this.sliderButtonsVisible = false,
  });

  final bool gyroEnabled;
  final int throttleTrim;
  final int steeringTrim;
  final bool sliderButtonsVisible;

  Map<String, Object> toJson() {
    return <String, Object>{
      'gyroEnabled': gyroEnabled,
      'throttleTrim': throttleTrim,
      'steeringTrim': steeringTrim,
      'sliderButtonsVisible': sliderButtonsVisible,
    };
  }

  /// 从本地数据恢复输入状态，并兼容旧版仅保存方向微调的记录。
  factory StoredControlInputState.fromJson(Map<String, Object?> json) {
    return StoredControlInputState(
      gyroEnabled: json['gyroEnabled'] as bool? ?? false,
      throttleTrim: ((json['throttleTrim'] as num?)?.toInt() ?? 0).clamp(
        -60,
        60,
      ),
      steeringTrim:
          ((json['steeringTrim'] as num?)?.toInt() ??
                  (json['trim'] as num?)?.toInt() ??
                  0)
              .clamp(-60, 60),
      sliderButtonsVisible: json['sliderButtonsVisible'] as bool? ?? false,
    );
  }
}

/// 控制页声音开关的可恢复状态。
class StoredControlSoundState {
  const StoredControlSoundState({
    this.backgroundSoundEnabled = true,
    this.effectSoundEnabled = true,
  });

  final bool backgroundSoundEnabled;
  final bool effectSoundEnabled;

  Map<String, Object> toJson() {
    return <String, Object>{
      'backgroundSoundEnabled': backgroundSoundEnabled,
      'effectSoundEnabled': effectSoundEnabled,
    };
  }

  /// 从本地数据恢复声音开关；没有旧记录时保持默认开启。
  factory StoredControlSoundState.fromJson(Map<String, Object?> json) {
    return StoredControlSoundState(
      backgroundSoundEnabled: json['backgroundSoundEnabled'] as bool? ?? true,
      effectSoundEnabled: json['effectSoundEnabled'] as bool? ?? true,
    );
  }
}

/// 控制页运行状态的本地存储。
///
/// 输入和声音使用独立键，避免两个控制器并发保存时相互覆盖。
class ControlRuntimeStore {
  static const _inputStorageKey = 'controller_app.control_input_runtime.v1';
  static const _soundStorageKey = 'controller_app.control_sound_runtime.v1';

  /// 读取陀螺仪与微调状态。
  Future<StoredControlInputState> loadInputState() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeInputState(prefs.getString(_inputStorageKey));
  }

  /// 保存陀螺仪与微调状态。
  Future<void> saveInputState(StoredControlInputState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_inputStorageKey, jsonEncode(state.toJson()));
  }

  /// 读取背景音乐与音效开关。
  Future<StoredControlSoundState> loadSoundState() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeSoundState(prefs.getString(_soundStorageKey));
  }

  /// 保存背景音乐与音效开关。
  Future<void> saveSoundState(StoredControlSoundState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundStorageKey, jsonEncode(state.toJson()));
  }
}

StoredControlInputState _decodeInputState(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const StoredControlInputState();
  }
  try {
    return StoredControlInputState.fromJson(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );
  } catch (_) {
    return const StoredControlInputState();
  }
}

StoredControlSoundState _decodeSoundState(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const StoredControlSoundState();
  }
  try {
    return StoredControlSoundState.fromJson(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );
  } catch (_) {
    return const StoredControlSoundState();
  }
}

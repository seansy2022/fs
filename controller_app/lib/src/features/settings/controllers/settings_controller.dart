import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings_state.dart';

class SettingsController extends StateNotifier<AppSettingsState> {
  SettingsController() : super(AppSettingsState.defaults()) {
    _load();
  }

  static const _storageKey = 'controller_app.settings.v1';

  void setHandedness(Handedness value) {
    state = state.copyWith(handedness: value);
    _persist();
  }

  void setControlMode(ControlMode value) {
    state = state.copyWith(controlMode: value);
    _persist();
  }

  void setGyroMode(GyroMode value) {
    state = state.copyWith(gyroMode: value);
    _persist();
  }

  void updateChannel(int index, ChannelSetting value) {
    final updated = state.channels.toList(growable: true);
    updated[index] = value;
    state = state.copyWith(channels: updated);
    _persist();
  }

  void updateTrackMix({double? left, double? right}) {
    state = state.copyWith(trackMixLeft: left, trackMixRight: right);
    _persist();
  }

  void updateBatterySettings({
    bool? enabled,
    BatteryType? batteryType,
    double? minimumVoltage,
    double? fullVoltage,
    double? alertPercent,
    bool? voice,
    bool? vibration,
  }) {
    var next = state.copyWith(
      lowVoltageEnabled: enabled,
      minimumVoltage: minimumVoltage,
      fullVoltage: fullVoltage,
      batteryAlertPercent: alertPercent,
      batteryVoice: voice,
      batteryVibration: vibration,
    );
    if (batteryType != null) {
      final defaults = _defaultsForBatteryType(batteryType, next);
      next = next.copyWith(
        batteryType: batteryType,
        minimumVoltage: defaults.minimumVoltage,
        fullVoltage: defaults.fullVoltage,
      );
    }
    state = next;
    _persist();
  }

  void updateSignalSettings({
    bool? enabled,
    double? threshold,
    bool? voice,
    bool? vibration,
  }) {
    state = state.copyWith(
      lowSignalEnabled: enabled,
      signalThreshold: threshold,
      signalVoice: voice,
      signalVibration: vibration,
    );
    _persist();
  }

  void updateReconnectAlerts({bool? voice, bool? vibration}) {
    state = state.copyWith(
      reconnectVoice: voice,
      reconnectVibration: vibration,
    );
    _persist();
  }

  void updateBackgroundMusic({BackgroundMusicMode? mode, String? name}) {
    state = state.copyWith(
      backgroundMusicMode: mode,
      backgroundMusicName: name,
    );
    _persist();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      state = AppSettingsState.fromStorageString(raw);
    } catch (_) {
      state = AppSettingsState.defaults();
    }
  }

  Future<void> _persist() async {
    final snapshot = state.toStorageString();
    unawaited(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, snapshot);
    }());
  }

  AppSettingsState _defaultsForBatteryType(
    BatteryType batteryType,
    AppSettingsState current,
  ) {
    switch (batteryType) {
      case BatteryType.twoCell:
        return current.copyWith(minimumVoltage: 6.2, fullVoltage: 8.4);
      case BatteryType.threeCell:
        return current.copyWith(minimumVoltage: 9.3, fullVoltage: 12.6);
      case BatteryType.custom:
        return current;
    }
  }
}

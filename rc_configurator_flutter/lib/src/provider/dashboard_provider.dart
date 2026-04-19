import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../types.dart';
import 'app_state_provider.dart';
import 'app_state_models.dart';

class DashboardState {
  const DashboardState({
    required this.telemetry,
    required this.channels,
    required this.models,
    required this.radioSettings,
    required this.mixingSettings,
  });

  final Telemetry telemetry;
  final List<ChannelState> channels;
  final List<Model> models;
  final RadioSettings radioSettings;
  final MixingSettings mixingSettings;

  DashboardState copyWith({
    Telemetry? telemetry,
    List<ChannelState>? channels,
    List<Model>? models,
    RadioSettings? radioSettings,
    MixingSettings? mixingSettings,
  }) {
    return DashboardState(
      telemetry: telemetry ?? this.telemetry,
      channels: channels ?? this.channels,
      models: models ?? this.models,
      radioSettings: radioSettings ?? this.radioSettings,
      mixingSettings: mixingSettings ?? this.mixingSettings,
    );
  }
}

class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    final app = ref.watch(rcAppStateProvider);
    return DashboardState(
      telemetry: app.telemetry,
      channels: app.channels,
      models: app.models,
      radioSettings: app.radioSettings,
      mixingSettings: app.mixingSettings,
    );
  }

  void updateChannel(String id, ChannelState next) {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(ChannelUpdatedIntent(id: id, next: next));
  }

  void selectModel(String id) {
    ref.read(rcAppStateProvider.notifier).dispatch(ModelSelectedIntent(id));
  }

  void renameModel(String id, String name) {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(ModelRenamedIntent(id: id, name: name));
  }

  void updateRadioSettings(RadioSettings next) {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(RadioSettingsUpdatedIntent(next));
  }

  void updateMixingSettings(MixingSettings next) {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(MixingSettingsUpdatedIntent(next));
  }
}

final dashboardProvider = NotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);

final telemetryProvider = Provider<Telemetry>((ref) {
  return ref.watch(dashboardProvider.select((state) => state.telemetry));
});

final channelsProvider = Provider<List<ChannelState>>((ref) {
  return ref.watch(dashboardProvider.select((state) => state.channels));
});

final modelsProvider = Provider<List<Model>>((ref) {
  return ref.watch(dashboardProvider.select((state) => state.models));
});

final radioSettingsProvider = Provider<RadioSettings>((ref) {
  return ref.watch(dashboardProvider.select((state) => state.radioSettings));
});

final mixingSettingsProvider = Provider<MixingSettings>((ref) {
  return ref.watch(dashboardProvider.select((state) => state.mixingSettings));
});

final activeModelNameProvider = Provider<String>((ref) {
  final models = ref.watch(modelsProvider);
  for (final model in models) {
    if (model.active) return model.name.isEmpty ? model.id : model.name;
  }
  return '';
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/controllers/settings_controller.dart';
import '../features/settings/models/app_settings_state.dart';

final appSettingsProvider =
    StateNotifierProvider<SettingsController, AppSettingsState>((ref) {
      return SettingsController();
    });

final appSettingsLoadedProvider = Provider<bool>((ref) {
  ref.watch(appSettingsProvider);
  return ref.watch(appSettingsProvider.notifier).isLoaded;
});

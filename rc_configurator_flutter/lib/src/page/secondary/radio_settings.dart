import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rc_ui/rc_ui.dart';
import 'package:rc_configurator_flutter/l10n/app_localizations.dart';
import '../../provider/locale_provider.dart';
import '../../types.dart';

const _cellHighlightBase = Color(0x281B2D4D);

class RadioSettingsView extends ConsumerWidget {
  const RadioSettingsView({
    super.key,
    required this.settings,
    required this.onUpdateSettings,
  });

  final RadioSettings settings;
  final ValueChanged<RadioSettings> onUpdateSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(AppDimens.gapL),
      children: [
        CellRateWidget(
          title: l10n.backlightTimeout,
          value: settings.backlightTime,
          suffix: '',
          enablePressRepeat: true,
          onMinus: () => _stepBacklight(settings, -1),
          onPlus: () => _stepBacklight(settings, 1),
        ),
        const SizedBox(height: AppDimens.gapM),
        CellRateWidget(
          title: l10n.standbyTimeout,
          value: settings.idleAlarm,
          suffix: '',
          enablePressRepeat: true,
          onMinus: () => _stepIdleAlarm(settings, -1),
          onPlus: () => _stepIdleAlarm(settings, 1),
        ),
        const SizedBox(height: AppDimens.gapM),
        CellSwitchWidget(
          title: l10n.ambientLight,
          value: settings.atmosphereLight,
          enableHighlight: true,
          highlightGradient: AppGradients.v24,
          highlightBaseColor: _cellHighlightBase,
          onChanged: (v) =>
              onUpdateSettings(settings.copyWith(atmosphereLight: v)),
        ),
        const SizedBox(height: AppDimens.gapM),
        CellIconTextWidget(
          enableHighlight: true,
          title: l10n.language,
          valueText: ref.watch(localeProvider).languageCode == 'zh'
              ? l10n.chinese
              : l10n.english,
          onTap: () => _showLanguageSheet(context, ref),
        ),
      ],
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    AlertSelectionSheet.show(
      context,
      title: l10n.language,
      options: [l10n.english, l10n.chinese],
      selectedOption: ref.read(localeProvider).languageCode == 'zh'
          ? l10n.chinese
          : l10n.english,
      onOptionSelected: (selected) {
        if (selected == l10n.chinese) {
          ref.read(localeProvider.notifier).setLocale(const Locale('zh'));
        } else {
          ref.read(localeProvider.notifier).setLocale(const Locale('en'));
        }
      },
    );
  }

  void _stepBacklight(RadioSettings settings, int delta) {
    final next = (settings.backlightTime + delta).clamp(0, 99);
    onUpdateSettings(settings.copyWith(backlightTime: next));
  }

  void _stepIdleAlarm(RadioSettings settings, int delta) {
    final next = (settings.idleAlarm + delta).clamp(10, 3600);
    onUpdateSettings(settings.copyWith(idleAlarm: next));
  }
}

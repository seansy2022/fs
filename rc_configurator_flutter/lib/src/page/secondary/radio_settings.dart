import 'package:flutter/material.dart';

import 'package:rc_ui/rc_ui.dart';
import '../../types.dart';

const _cellHighlightBase = Color(0x281B2D4D);

class RadioSettingsView extends StatelessWidget {
  const RadioSettingsView({
    super.key,
    required this.settings,
    required this.onUpdateSettings,
  });

  final RadioSettings settings;
  final ValueChanged<RadioSettings> onUpdateSettings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.gapL),
      children: [
        CellRateWidget(
          title: '背光时间',
          value: settings.backlightTime,
          suffix: '',
          enablePressRepeat: true,
          onMinus: () => _stepBacklight(settings, -1),
          onPlus: () => _stepBacklight(settings, 1),
        ),
        const SizedBox(height: AppDimens.gapM),
        CellRateWidget(
          title: '闲置报警',
          value: settings.idleAlarm,
          suffix: '',
          enablePressRepeat: true,
          onMinus: () => _stepIdleAlarm(settings, -1),
          onPlus: () => _stepIdleAlarm(settings, 1),
        ),
        const SizedBox(height: AppDimens.gapM),
        CellSwitchWidget(
          title: '氛围灯',
          value: settings.atmosphereLight,
          enableHighlight: true,
          highlightGradient: AppGradients.v24,
          highlightBaseColor: _cellHighlightBase,
          onChanged: (v) =>
              onUpdateSettings(settings.copyWith(atmosphereLight: v)),
        ),
      ],
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

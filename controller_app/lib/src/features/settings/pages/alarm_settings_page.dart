import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../models/app_settings_state.dart';
import '../widgets/settings_workspace.dart';

class AlarmSettingsPage extends ConsumerWidget {
  const AlarmSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsWorkspace(
      activeRoute: AppRoutes.alarms,
      onBack: () => Navigator.of(context).pop(),
      content: const AlarmSettingsContent(),
    );
  }
}

class AlarmSettingsContent extends ConsumerWidget {
  const AlarmSettingsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        children: [
          SettingsStrip(
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '模型低电压报警',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          // fontWeight: AppFonts.w500,
                        ),
                      ),
                    ),
                    TechSwitch(
                      value: settings.lowVoltageEnabled,
                      onChanged: (value) =>
                          controller.updateBatterySettings(enabled: value),
                    ),
                  ],
                ),
                // const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SettingsStrip(
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '模型低信号报警',
                        style: TextStyle(color: AppColors.text, fontSize: 14),
                      ),
                    ),
                    TechSwitch(
                      value: settings.lowSignalEnabled,
                      onChanged: (value) =>
                          controller.updateSignalSettings(enabled: value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SettingsStrip(
            // height: 88,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '模型断开/连上提示',
                    style: TextStyle(color: AppColors.text, fontSize: 14),
                  ),
                ),
                _BinaryFlag(
                  label: '语音',
                  value: settings.reconnectVoice,
                  onChanged: (value) =>
                      controller.updateReconnectAlerts(voice: value),
                ),
                const SizedBox(width: 8),
                _BinaryFlag(
                  label: '振动',
                  value: settings.reconnectVibration,
                  onChanged: (value) =>
                      controller.updateReconnectAlerts(vibration: value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSlider extends StatelessWidget {
  const _MiniSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textDim, fontSize: 14),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: const TextStyle(
                color: AppColors.primaryBright,
                fontSize: 16,
                fontWeight: AppFonts.w700,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _BinaryFlag extends StatelessWidget {
  const _BinaryFlag({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: PrimaryButton(
        text: label,
        type: value ? PrimaryButtonType.primary : PrimaryButtonType.normal,
        onTap: () => onChanged(!value),
      ),
    );
  }
}

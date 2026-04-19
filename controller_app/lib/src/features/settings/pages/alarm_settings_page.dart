import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../models/app_settings_state.dart';
import '../widgets/select_option_toggle.dart';
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
            child: CellSwitchWidget(
              title: '低模型电压报警',
              value: settings.lowVoltageEnabled,
              onChanged: (value) =>
                  controller.updateBatterySettings(enabled: value),
            ),
          ),
          if (settings.lowVoltageEnabled) ...[
            const SizedBox(height: 8),
            SettingsStrip(
              child: Padding(
                padding: const EdgeInsets.only(left: 40, right: 16),
                child: Row(
                  children: [
                    const Text(
                      '电量转换',
                      style: TextStyle(color: AppColors.text, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    RCButton(
                      onTap: () => controller.updateBatterySettings(
                        batteryType: settings.batteryType == BatteryType.custom
                            ? BatteryType.twoCell
                            : BatteryType.custom,
                      ),
                      active: settings.batteryType == BatteryType.custom,
                      enableRepeat: false,
                      width: 72,
                      height: 32,
                      textWidget: Text(
                        '其他',
                        style: TextStyle(
                          color: settings.batteryType == BatteryType.custom
                              ? AppColors.text
                              : AppColors.textDim,
                          fontSize: 14,
                          fontWeight: AppFonts.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '最低电压',
                          style: TextStyle(color: AppColors.text, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        RCButton(
                          onTap: () => controller.updateBatterySettings(
                            minimumVoltage: 6,
                          ),
                          active: (settings.minimumVoltage - 6).abs() < 0.05,
                          enableRepeat: false,
                          width: 64,
                          height: 32,
                          textWidget: Text(
                            '6伏',
                            style: TextStyle(
                              color: (settings.minimumVoltage - 6).abs() < 0.05
                                  ? AppColors.text
                                  : AppColors.textDim,
                              fontSize: 14,
                              fontWeight: AppFonts.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 40),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '满电电压',
                          style: TextStyle(color: AppColors.text, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        _InputBox(
                          text: '${settings.fullVoltage.toStringAsFixed(1)}V',
                          onSubmitted: (raw) {
                            final value = _extractNumber(raw);
                            if (value == null) return;
                            controller.updateBatterySettings(fullVoltage: value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SettingsStrip(
              child: Padding(
                padding: const EdgeInsets.only(right: 40),
                child: _LabeledRow(
                  title: '报警电量',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${settings.minimumVoltage.toStringAsFixed(1)}伏',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _InputBox(
                        text: '${settings.batteryAlertPercent.round()}%',
                        onSubmitted: (raw) {
                          final value = _extractNumber(raw);
                          if (value == null) return;
                          controller.updateBatterySettings(
                            alertPercent: value.clamp(0, 100),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SettingsStrip(
              child: Padding(
                padding: const EdgeInsets.only(right: 40),
                child: _LabeledRow(
                  title: '报警提示',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SelectOptionToggle(
                        selected: settings.batteryVoice,
                        label: '语音',
                        onTap: () => controller.updateBatterySettings(
                          voice: true,
                          vibration: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SelectOptionToggle(
                        selected: settings.batteryVibration,
                        label: '震动',
                        onTap: () => controller.updateBatterySettings(
                          voice: false,
                          vibration: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SettingsStrip(
            child: CellSwitchWidget(
              title: '模型低信号报警',
              value: settings.lowSignalEnabled,
              onChanged: (value) =>
                  controller.updateSignalSettings(enabled: value),
            ),
          ),
          if (settings.lowSignalEnabled) ...[
            const SizedBox(height: 8),
            SettingsStrip(
              child: Column(
                children: [
                  _LabeledRow(
                    title: '报警信号值',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '低于',
                          style: TextStyle(color: AppColors.text, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        _InputBox(
                          text: settings.signalThreshold.round().toString(),
                          onSubmitted: (raw) {
                            final value = _extractNumber(raw);
                            if (value == null) return;
                            controller.updateSignalSettings(
                              threshold: value.clamp(0, 100),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabeledRow(
                    title: '报警提示',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SelectOptionToggle(
                          selected: settings.signalVoice,
                          label: '语音',
                          onTap: () => controller.updateSignalSettings(
                            voice: true,
                            vibration: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SelectOptionToggle(
                          selected: settings.signalVibration,
                          label: '震动',
                          onTap: () => controller.updateSignalSettings(
                            voice: false,
                            vibration: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          SettingsStrip(
            child: _LabeledRow(
              title: '模型断开/连上提示',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectOptionToggle(
                    selected: settings.reconnectVoice,
                    label: '语音',
                    onTap: () => controller.updateReconnectAlerts(
                      voice: true,
                      vibration: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SelectOptionToggle(
                    selected: settings.reconnectVibration,
                    label: '滚动',
                    onTap: () => controller.updateReconnectAlerts(
                      voice: false,
                      vibration: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: AppColors.text, fontSize: 14),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({required this.text, required this.onSubmitted});

  final String text;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 28,
      child: TextFormField(
        key: ValueKey(text),
        initialValue: text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: AppFonts.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          filled: true,
          fillColor: const Color(0xFF0A1E3A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF2C4A73), width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF2C4A73), width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.primaryBright, width: 1),
          ),
        ),
        onFieldSubmitted: onSubmitted,
      ),
    );
  }
}

double? _extractNumber(String raw) {
  final cleaned = raw.trim().replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

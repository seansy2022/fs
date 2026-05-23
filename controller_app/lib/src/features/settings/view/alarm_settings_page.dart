import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../controllers/settings_controller.dart';
import '../models/app_settings_state.dart';
import '../widgets/numeric_input_dialog.dart';
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
            child: _LabeledRow(
              title: '低模型电压报警',
              trailing: _AlarmToggleSwitch(
                value: settings.lowVoltageEnabled,
                onChanged: (value) =>
                    controller.updateBatterySettings(enabled: value),
              ),
            ),
          ),
          if (settings.lowVoltageEnabled) ...[
            const SizedBox(height: 8),
            SettingsStrip(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '电量转换',
                          style: TextStyle(color: AppColors.text, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        RCButton(
                          onTap: () => _showBatteryTypeDialog(
                            context,
                            settings.batteryType,
                            controller,
                          ),
                          active: true,
                          enableRepeat: false,
                          width: 72,
                          height: 32,
                          textWidget: Text(
                            _batteryTypeLabel(settings.batteryType),
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: AppFonts.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '最低电压',
                          style: TextStyle(color: AppColors.text, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        _TapInputBox(
                          text:
                              '${_formatDisplayNumber(settings.minimumVoltage)}V',
                          onTap: () async {
                            final raw = await NumericInputDialog.show(
                              context,
                              title: '最低电压',
                              initialValue: _formatDisplayNumber(
                                settings.minimumVoltage,
                              ),
                              unit: 'V',
                            );
                            final value = _extractNumber(raw ?? '');
                            if (value == null) return;
                            controller.updateBatterySettings(
                              minimumVoltage: _clampMinimumVoltage(
                                value,
                                settings,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '满电电压',
                          style: TextStyle(color: AppColors.text, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        _TapInputBox(
                          text:
                              '${_formatDisplayNumber(settings.fullVoltage)}V',
                          onTap: () async {
                            final raw = await NumericInputDialog.show(
                              context,
                              title: '满电电压',
                              initialValue: _formatDisplayNumber(
                                settings.fullVoltage,
                              ),
                              unit: 'V',
                            );
                            final value = _extractNumber(raw ?? '');
                            if (value == null) return;
                            controller.updateBatterySettings(
                              fullVoltage: _clampFullVoltage(value, settings),
                            );
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
                padding: const EdgeInsets.only(left: 20, right: 40),
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
                      _TapInputBox(
                        text: '${settings.batteryAlertPercent.round()}%',
                        onTap: () async {
                          final raw = await NumericInputDialog.show(
                            context,
                            title: '报警电量',
                            initialValue: settings.batteryAlertPercent
                                .round()
                                .toString(),
                            unit: '%',
                          );
                          final value = _extractNumber(raw ?? '');
                          if (value == null) return;
                          controller.updateBatterySettings(
                            alertPercent: value.clamp(0, 99),
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
                padding: const EdgeInsets.only(left: 20, right: 40),
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
            child: _LabeledRow(
              title: '模型低信号报警',
              trailing: _AlarmToggleSwitch(
                value: settings.lowSignalEnabled,
                onChanged: (value) =>
                    controller.updateSignalSettings(enabled: value),
              ),
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
                        _TapInputBox(
                          text: '${settings.signalThreshold.round()}%',
                          onTap: () async {
                            final raw = await NumericInputDialog.show(
                              context,
                              title: '报警信号值',
                              initialValue: settings.signalThreshold
                                  .round()
                                  .toString(),
                              unit: '%',
                            );
                            final value = _extractNumber(raw ?? '');
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

void _showBatteryTypeDialog(
  BuildContext context,
  BatteryType current,
  SettingsController controller,
) {
  final options = BatteryType.values
      .map(_batteryTypeLabel)
      .toList(growable: false);

  AlertListDialog.show(
    context,
    title: '选择电池类型',
    width: 350,
    options: options,
    selectedOption: _batteryTypeLabel(current),
    onOptionSelected: (selection) {
      final type = BatteryType.values.firstWhere(
        (value) => _batteryTypeLabel(value) == selection,
      );
      controller.updateBatterySettings(batteryType: type);
    },
  );
}

String _batteryTypeLabel(BatteryType type) {
  switch (type) {
    case BatteryType.oneCell:
      return '1S';
    case BatteryType.twoCell:
      return '2S';
    case BatteryType.threeCell:
      return '3S';
    case BatteryType.fourCell:
      return '4S';
    case BatteryType.other:
      return '其他';
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

class _AlarmToggleSwitch extends StatelessWidget {
  const _AlarmToggleSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 52,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? null : const Color(0xFF465D7A),
          gradient: value
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF0072FF), Color(0xFF00C8FF)],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF7DA2CE).withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFEDF5FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x40001024),
                  blurRadius: 4,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TapInputBox extends StatelessWidget {
  const _TapInputBox({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 72,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0A1E3A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF2C4A73), width: 0.8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: AppFonts.w600,
          ),
        ),
      ),
    );
  }
}

double? _extractNumber(String raw) {
  final cleaned = raw.trim().replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty || cleaned.length > 4) return null;
  return double.tryParse(cleaned);
}

double _clampMinimumVoltage(double value, AppSettingsState settings) {
  final upperBound = (settings.fullVoltage - 1).clamp(2.5, 29.0);
  return _roundToTenth(value.clamp(2.5, upperBound));
}

double _clampFullVoltage(double value, AppSettingsState settings) {
  final lowerBound = (settings.minimumVoltage + 1).clamp(3.5, 30.0);
  return _roundToTenth(value.clamp(lowerBound, 30.0));
}

double _roundToTenth(double value) => (value * 10).roundToDouble() / 10;

String _formatDisplayNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../../core/providers.dart';
import '../../models/gear_settings.dart';
import '../../widgets/numeric_input_dialog.dart';
import '../../widgets/settings_workspace.dart';
import 'package:controller_app/src/core/localization/app_localizations.dart';

const gearLowReverseFieldKey = ValueKey<String>('gear-low-reverse-field');
const gearLowForwardFieldKey = ValueKey<String>('gear-low-forward-field');
const gearHighReverseFieldKey = ValueKey<String>('gear-high-reverse-field');
const gearHighForwardFieldKey = ValueKey<String>('gear-high-forward-field');

class GearSettingsContent extends ConsumerWidget {
  const GearSettingsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).gearSettings;
    final controller = ref.read(appSettingsProvider.notifier);
    return Column(
      children: [
        SettingsStrip(
          child: _GearSettingRow(
            label: '低速',
            reverseValue: settings.lowReversePercent.round(),
            forwardValue: settings.lowForwardPercent.round(),
            reverseKey: gearLowReverseFieldKey,
            forwardKey: gearLowForwardFieldKey,
            onReverseTap: () => _editPercent(
              context,
              title: '设置低速后退比例',
              initialValue: settings.lowReversePercent,
              onChanged: (value) =>
                  controller.updateGearRatios(lowReverse: value.toDouble()),
            ),
            onForwardTap: () => _editPercent(
              context,
              title: '设置低速前进比例',
              initialValue: settings.lowForwardPercent,
              onChanged: (value) =>
                  controller.updateGearRatios(lowForward: value.toDouble()),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SettingsStrip(
          child: _GearSettingRow(
            label: '高速',
            reverseValue: settings.highReversePercent.round(),
            forwardValue: settings.highForwardPercent.round(),
            reverseKey: gearHighReverseFieldKey,
            forwardKey: gearHighForwardFieldKey,
            onReverseTap: () => _editPercent(
              context,
              title: '设置高速后退比例',
              initialValue: settings.highReversePercent,
              onChanged: (value) =>
                  controller.updateGearRatios(highReverse: value.toDouble()),
            ),
            onForwardTap: () => _editPercent(
              context,
              title: '设置高速前进比例',
              initialValue: settings.highForwardPercent,
              onChanged: (value) =>
                  controller.updateGearRatios(highForward: value.toDouble()),
            ),
          ),
        ),
      ],
    );
  }

  /// 弹出与其他设置页一致的百分比输入框，并保存有效输入。
  Future<void> _editPercent(
    BuildContext context, {
    required String title,
    required double initialValue,
    required ValueChanged<int> onChanged,
  }) async {
    final raw = await NumericInputDialog.show(
      context,
      title: AppText.tr(title),
      initialValue: initialValue.round().toString(),
      unit: '%',
      allowDecimal: false,
      maxAbsValue: 100,
      maxLength: 3,
    );
    final value = int.tryParse(raw?.trim() ?? '');
    if (value == null) {
      return;
    }
    onChanged(normalizeGearPercent(value).round());
  }
}

class _GearSettingRow extends StatelessWidget {
  const _GearSettingRow({
    required this.label,
    required this.reverseValue,
    required this.forwardValue,
    required this.reverseKey,
    required this.forwardKey,
    required this.onReverseTap,
    required this.onForwardTap,
  });

  final String label;
  final int reverseValue;
  final int forwardValue;
  final Key reverseKey;
  final Key forwardKey;
  final VoidCallback onReverseTap;
  final VoidCallback onForwardTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            AppText.tr(label),
            style: const TextStyle(color: AppColors.text, fontSize: 14),
          ),
        ),
        const Spacer(),
        Text(
          AppText.tr('后退比例'),
          style: TextStyle(color: AppColors.text, fontSize: 14),
        ),
        const SizedBox(width: 12),
        _GearPercentField(
          key: reverseKey,
          value: reverseValue,
          onTap: onReverseTap,
        ),
        const SizedBox(width: 56),
        Text(
          AppText.tr('前进比例'),
          style: TextStyle(color: AppColors.text, fontSize: 14),
        ),
        const SizedBox(width: 12),
        _GearPercentField(
          key: forwardKey,
          value: forwardValue,
          onTap: onForwardTap,
        ),
      ],
    );
  }
}

class _GearPercentField extends StatelessWidget {
  const _GearPercentField({
    super.key,
    required this.value,
    required this.onTap,
  });

  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RCButton(
      onTap: onTap,
      active: false,
      enableRepeat: false,
      width: 60,
      height: 28,
      padding: EdgeInsets.zero,
      textWidget: Text(
        '$value%',
        style: const TextStyle(color: AppColors.textDim, fontSize: 14),
      ),
    );
  }
}

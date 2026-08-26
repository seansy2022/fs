import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';
import 'package:controller_app/src/core/localization/app_localizations.dart';

import '../../widgets/numeric_input_dialog.dart';

const _calibrationHintText =
    '自定义控制校准\n根据右图示意和实时旋转角度\n参考，请前后转动手机选择适\n合自己的控制角度，并输入对\n应控制角度完成自定义控制校\n准。';

/// 一个可复用的角度输入项；油门和方向校准共用相同外观。
class GyroDegreeInputData {
  const GyroDegreeInputData({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;
}

/// 体感校准面板：标题、三个角度输入、说明及实时姿态示意图。
class GyroAxisCalibrationPanel extends StatelessWidget {
  const GyroAxisCalibrationPanel({
    super.key,
    required this.title,
    required this.currentDegree,
    required this.inputs,
    required this.isInputValid,
  }) : assert(inputs.length == 3);

  final String title;
  final double currentDegree;
  final List<GyroDegreeInputData> inputs;
  final bool Function(TextEditingController controller, String value)
  isInputValid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppText.tr(title),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: AppFonts.w600,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            for (var index = 0; index < inputs.length; index++) ...[
              Expanded(
                child: GyroDegreeInput(
                  data: inputs[index],
                  isInputValid: isInputValid,
                ),
              ),
              if (index < inputs.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              const Expanded(flex: 2, child: _CalibrationHint()),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: RealtimeAngleIllustration(degree: currentDegree),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GyroDegreeInput extends StatelessWidget {
  const GyroDegreeInput({super.key, required this.data, this.isInputValid});

  final GyroDegreeInputData data;
  final bool Function(TextEditingController controller, String value)?
  isInputValid;

  /// 打开通用数值弹窗；只有用户在弹窗内提交后，才回写当前校准草稿。
  Future<void> _editDegree(BuildContext context) async {
    final value = await NumericInputDialog.show(
      context,
      title: AppText.tr(data.label),
      initialValue: data.controller.text,
      unit: '°',
      allowSigned: true,
      allowDecimal: true,
      maxAbsValue: 90,
      maxLength: 5,
    );
    if (value == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    // 完成输入时先验证当前轴三点关系，失败时不覆盖原有草稿。
    if (isInputValid?.call(data.controller, value) == false) {
      RcToast.show(context, message: AppText.tr('输入不符合规范，已恢复原值。'));
      return;
    }
    data.controller.text = value;
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Localizations.localeOf(context).languageCode == 'en'
        ? 10.0
        : 11.0;
    return Column(
      children: [
        Text(
          AppText.tr(data.label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textDim, fontSize: fontSize),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          key: ValueKey<String>('gyro-degree-input-${data.label}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _editDegree(context),
          child: Container(
            height: 30,
            constraints: const BoxConstraints(maxWidth: 78),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0x661B2D4D),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppColors.primary, width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: data.controller,
                    builder: (context, value, child) => Text(
                      value.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const Text(
                  '°',
                  style: TextStyle(color: AppColors.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CalibrationHint extends StatelessWidget {
  const _CalibrationHint();

  @override
  Widget build(BuildContext context) {
    final localizedHint = AppText.tr(_calibrationHintText);
    final titleEnd = localizedHint.indexOf('\n');
    final title = titleEnd < 0
        ? localizedHint
        : localizedHint.substring(0, titleEnd);
    final description = titleEnd < 0
        ? ''
        : localizedHint.substring(titleEnd + 1);
    final fontSize = Localizations.localeOf(context).languageCode == 'en'
        ? 5.0
        : 6.0;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: AppFonts.w700,
              ),
            ),
            if (description.isNotEmpty)
              TextSpan(
                text: '\n$description',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: fontSize,
                  height: 1.35,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 单独受尺寸约束的实时姿态图，避免使用整张校准页 SVG 缩放。
class RealtimeAngleIllustration extends StatelessWidget {
  const RealtimeAngleIllustration({super.key, required this.degree});

  final double degree;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 180.0);
        final height = math.min(constraints.maxHeight, 78.0);
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/gyro_calibration_phone.png',
                  width: width,
                  height: height,
                  fit: BoxFit.contain,
                ),
                _RealtimeDegreeOverlay(degree: degree),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 用实时角度覆盖素材中静态的 45°，确保姿态变化立即反映到画面。
class _RealtimeDegreeOverlay extends StatelessWidget {
  const _RealtimeDegreeOverlay({required this.degree});

  final double degree;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${degree.round()}°',
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: AppFonts.w500,
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rc_ui/rc_ui.dart';
import 'package:controller_app/src/core/localization/app_localizations.dart';

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
    required this.showInputError,
    required this.onInputChanged,
  }) : assert(inputs.length == 3);

  final String title;
  final double currentDegree;
  final List<GyroDegreeInputData> inputs;
  final bool showInputError;
  final VoidCallback onInputChanged;

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
                  showError: showInputError,
                  onChanged: onInputChanged,
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
  const GyroDegreeInput({
    super.key,
    required this.data,
    required this.showError,
    required this.onChanged,
  });

  final GyroDegreeInputData data;
  final bool showError;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppText.tr(data.label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textDim, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Container(
          height: 30,
          constraints: const BoxConstraints(maxWidth: 78),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0x661B2D4D),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: showError ? AppColors.tertiary : AppColors.primary,
              width: 0.8,
            ),
          ),
          child: TextField(
            controller: data.controller,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
              LengthLimitingTextInputFormatter(5),
            ],
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged(),
            style: const TextStyle(color: AppColors.text, fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              suffixText: '°',
              suffixStyle: TextStyle(color: AppColors.textDim, fontSize: 11),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        AppText.tr(
          '自定义X控制校准\n根据右图示意和实时旋转角度\n参考，请前后转动手机选择适\n合自己的控制角度，并输入对\n应控制角度完成自定义控制校\n准。',
        ),
        style: TextStyle(color: AppColors.textDim, fontSize: 6, height: 1.35),
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

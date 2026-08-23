import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../core/localization/app_localizations.dart';

/// 履带混控方向标签。
class TankMixMetricLabel extends StatelessWidget {
  const TankMixMetricLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppText.tr(label),
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 14,
        fontWeight: AppFonts.w600,
      ),
    );
  }
}

/// 履带混控数值输入按钮，关闭时灰化并禁用交互。
class TankMixValueButton extends StatelessWidget {
  const TankMixValueButton({
    super.key,
    required this.value,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool enabled;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: RCButton(
        onTap: onTap,
        active: selected,
        enableRepeat: false,
        width: 74,
        height: 34,
        textWidget: Text(
          '$value%',
          style: TextStyle(
            color: selected ? AppColors.text : AppColors.textDim,
            fontSize: 11,
            fontWeight: AppFonts.w600,
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class TechSegmented extends StatelessWidget {
  const TechSegmented({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.isRight,
    required this.onChanged,
  });

  final String leftLabel;
  final String rightLabel;
  final bool isRight;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x990072FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(leftLabel, !isRight, () => onChanged(false)),
          _segment(rightLabel, isRight, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? null : Colors.transparent,
          gradient: active ? AppGradients.primary : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.onPrimary : AppColors.textDim,
            fontSize: AppFonts.s11,
            fontWeight: AppFonts.w700,
          ),
        ),
      ),
    );
  }
}

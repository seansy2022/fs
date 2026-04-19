
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class TechSwitch extends StatelessWidget {
  const TechSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.onLabel = 'ON',
    this.offLabel = 'OFF',
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String onLabel;
  final String offLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 86,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x990072FF)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 38,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      offLabel,
                      style: TextStyle(
                        color: value ? AppColors.textDim : AppColors.onPrimary,
                        fontSize: AppFonts.s10,
                        fontWeight: AppFonts.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      onLabel,
                      style: TextStyle(
                        color: value ? AppColors.onPrimary : AppColors.textDim,
                        fontSize: AppFonts.s10,
                        fontWeight: AppFonts.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

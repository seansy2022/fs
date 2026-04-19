import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class ButtonCell extends StatelessWidget {
  const ButtonCell({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.height = 120,
    this.fontSize = 32,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final h = AppDimens.compactCell(height);
    final fs = AppFonts.compactFont(fontSize);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: AppDimens.compactCell(24)),
        decoration: BoxDecoration(
          color: const Color(0x291B2D4D),
          borderRadius: BorderRadius.circular(AppDimens.compactCell(16)),
          border: Border.all(color: const Color(0xFF0072FF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D0072FF),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: AppFonts.w500,
                ).copyWith(fontSize: fs),
              ),
            ),
            _SwitchPill(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _SwitchPill extends StatelessWidget {
  const _SwitchPill({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final w = AppDimens.compactCell(104);
    final h = AppDimens.compactCell(56);
    final p = AppDimens.compactCell(4);
    final r = AppDimens.compactCell(28);
    final knob = AppDimens.compactCell(48);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: w,
        height: h,
        padding: EdgeInsets.all(p),
        decoration: BoxDecoration(
          color: value ? null : const Color(0xFF465D7A),
          gradient: value
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.primary, AppColors.primaryBright],
                )
              : null,
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: const Color(0x667DA2CE)),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: knob,
            height: knob,
            decoration: BoxDecoration(
              color: AppColors.onPrimary,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x40001024), blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

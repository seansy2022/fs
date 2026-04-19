import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:rc_ui/src/elements/button/rc_icon_button.dart';

class DoubleRate extends StatelessWidget {
  const DoubleRate({
    super.key,
    required this.label,
    required this.value,
    required this.onChange,
    this.min = 0,
    this.max = 100,
    this.step = 1,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChange;

  int _clamp(int next) => next.clamp(min, max);

  @override
  Widget build(BuildContext context) {
    final cellH = AppDimens.compactCell(72);
    final px = AppDimens.compactCell(12);
    final side = AppDimens.compactCell(48);
    final iconSize = AppDimens.compactIcon(22);
    
    return Container(
      height: cellH,
      padding: EdgeInsets.symmetric(horizontal: px),
      decoration: BoxDecoration(
        color: const Color(0x291B2D4D),
        borderRadius: BorderRadius.circular(AppDimens.compactCell(12)),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: _text(16, AppColors.onPrimary))),
          RCIconButton(
            plus: false, 
            onTap: () => onChange(_clamp(value - step)),
            size: side,
            iconSize: iconSize,
          ),
          SizedBox(width: AppDimens.compactCell(8)),
          _valueBox(),
          SizedBox(width: AppDimens.compactCell(8)),
          RCIconButton(
            plus: true, 
            onTap: () => onChange(_clamp(value + step)),
            size: side,
            iconSize: iconSize,
          ),
        ],
      ),
    );
  }

  Widget _valueBox() {
    final w = AppDimens.compactCell(100);
    final h = AppDimens.compactCell(48);
    return Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2D4D),
        borderRadius: BorderRadius.circular(AppDimens.compactCell(8)),
      ),
      child: Text('$value%', style: _text(18, AppColors.onPrimary, true)),
    );
  }

  TextStyle _text(double size, Color color, [bool bold = false]) {
    return TextStyle(
      fontSize: AppFonts.compactFont(size),
      color: color,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    );
  }
}

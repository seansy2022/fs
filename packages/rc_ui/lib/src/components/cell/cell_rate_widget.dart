
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';
import 'package:rc_ui/src/elements/button/rc_icon_button.dart';
import 'cell.dart';

class CellRateWidget extends StatelessWidget {
  const CellRateWidget({
    super.key,
    required this.title,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.suffix = '%',
    this.showBorder = true,
    this.titleFontSize = AppFonts.s14,
    this.valueFontSize = AppFonts.s14,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
    this.enablePressRepeat = true,
  });

  final String title;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final String suffix;
  final bool showBorder;
  final double titleFontSize;
  final double valueFontSize;
  final EdgeInsetsGeometry padding;
  final bool enablePressRepeat;

  @override
  Widget build(BuildContext context) {
    final side = AppDimens.compactCell(60);
    final iconSize = AppDimens.compactIcon(36);
    return Cell(
      title: title,
      padding: padding,
      height: 120,
      showBorder: showBorder,
      titleFontSize: titleFontSize,
      widget: Row(
        children: [
          _wrap(
            RCIconButton(
              plus: false, 
              onTap: onMinus, 
              size: side, 
              iconSize: iconSize,
              enableRepeat: enablePressRepeat,
            ),
          ),
          _valueBox(),
          _wrap(
            RCIconButton(
              plus: true, 
              onTap: onPlus, 
              size: side, 
              iconSize: iconSize,
              enableRepeat: enablePressRepeat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrap(Widget child) {
    return Padding(
      padding: EdgeInsets.only(right: AppDimens.compactCell(8)),
      child: child,
    );
  }

  Widget _valueBox() {
    return Container(
      width: AppDimens.compactCell(160),
      height: AppDimens.compactCell(60),
      alignment: Alignment.center,
      margin: EdgeInsets.only(right: AppDimens.compactCell(8)),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(AppDimens.compactCell(4)),
      ),
      child: Text('$value$suffix', style: _valueStyle()),
    );
  }

  TextStyle _valueStyle() {
    return TextStyle(
      color: AppColors.onPrimary,
      fontSize: valueFontSize,
      fontWeight: AppFonts.w400,
      height: 1,
    );
  }
}

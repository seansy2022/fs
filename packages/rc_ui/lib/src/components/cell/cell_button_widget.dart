
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

import 'cell.dart';

class CellButtonWidget extends StatelessWidget {
  const CellButtonWidget({
    super.key,
    required this.title,
    required this.buttonText,
    required this.onPressed,
    this.active = false,
  });

  final String title;
  final String buttonText;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Cell(
      title: title,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
      widget: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          height: AppDimens.compactCell(60),
          // margin: EdgeInsets.symmetric(vertical: AppDimens.compactCell(10)),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.compactCell(24),
            // vertical: AppDimens.compactCell(12),
          ),
          alignment: Alignment.center,
          decoration: _decoration(),
          child: Text(buttonText, style: _textStyle()),
        ),
      ),
    );
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: active ? null : const Color(0xFF1B2D4D),
      gradient: active
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF00C8FF), Color(0xFF0072FF)],
            )
          : null,
      borderRadius: BorderRadius.circular(AppDimens.compactCell(4)),
    );
  }

  TextStyle _textStyle() {
    return TextStyle(
      color: active ? AppColors.bg : AppColors.onPrimary,
      fontSize: AppFonts.s14,
      // fontWeight: AppFonts.w700,
      height: 1,
    );
  }
}

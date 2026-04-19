
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class SelectableButtonWidget extends StatelessWidget {
  const SelectableButtonWidget({
    super.key,
    required this.title,
    this.selected = false,
    this.width,
    this.fontSize = AppFonts.s16,
    this.textColor,
    this.onTap,
  });

  final String title;
  final bool selected;
  final double? width;
  final double fontSize;
  final Color? textColor;
  final VoidCallback? onTap;
  static const _scale = 0.5;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width ?? 212 * _scale,
        height: 80 * _scale,
        decoration: _decoration(),
        child: Center(
          child: Text(title, textAlign: TextAlign.center, style: _textStyle()),
        ),
      ),
    );
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: const Color(0x661B2D4D),
      borderRadius: BorderRadius.circular(8 * _scale),
      gradient: selected
          ? const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0x8000C6FF), Color(0x0000C6FF)],
            )
          : null,
      border: Border.all(
        color: selected ? const Color(0xFF00C6FF) : const Color(0xFF0072FF),
        width: _scale,
      ),
      boxShadow: const [
        // BoxShadow(
        //   color: Color.fromARGB(66, 0, 115, 255),
        //   blurRadius: 2,
        //   spreadRadius: -1,
        // ),
      ],
    );
  }

  TextStyle _textStyle() {
    return TextStyle(
      color:
          textColor ??
          (selected ? const Color(0xFFEDF5FF) : const Color(0xFF7DA2CE)),
      fontSize: fontSize,
      fontFamily: AppFonts.pingFangSc,
      height: 1,
    );
  }
}

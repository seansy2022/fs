import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';
import '../../../elements/button/rc_icon_button.dart';

class ItemButton extends StatelessWidget {
  const ItemButton({
    super.key,
    required this.text,
    required this.selected,
    this.onTap,
    this.width = 60,
    this.height = 28,
    this.fontSize = AppFonts.s12,
    this.enableRepeat = false,
    this.type = RCIconButtonType.normal,
  });

  final String text;
  final bool selected;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final double fontSize;
  final bool enableRepeat;
  final RCIconButtonType type;

  @override
  Widget build(BuildContext context) {
    return RCIconButton(
      text: text,
      active: selected,
      onTap: onTap,
      enableRepeat: enableRepeat,
      width: width,
      size: height,
      isSquare: false,
      padding: EdgeInsets.zero,
      fontSize: fontSize,
      type: type,
    );
  }
}

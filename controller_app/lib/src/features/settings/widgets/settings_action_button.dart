import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

class SettingsActionButton extends StatelessWidget {
  const SettingsActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 74,
    this.height = 30,
    this.textStyle,
  });

  final String label;
  final VoidCallback onTap;
  final double width;
  final double height;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF23385C),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              textStyle ?? const TextStyle(color: AppColors.text, fontSize: 14),
        ),
      ),
    );
  }
}

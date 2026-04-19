
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class TechTitle extends StatelessWidget {
  const TechTitle(this.text, {super.key, this.sub});

  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sub != null)
          Text(
            sub!,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: AppFonts.s10,
              letterSpacing: 1.2,
              fontWeight: AppFonts.w600,
            ),
          ),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: AppFonts.s20,
            letterSpacing: 0.5,
            fontWeight: AppFonts.w700,
          ),
        ),
      ],
    );
  }
}

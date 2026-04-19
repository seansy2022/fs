import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class BlueLoadingBase extends StatelessWidget {
  const BlueLoadingBase({super.key, required this.text, required this.middle});

  final String text;
  final Widget middle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xE0001024),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1B2D4D), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          middle,
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: AppFonts.s14),
          ),
        ],
      ),
    );
  }
}

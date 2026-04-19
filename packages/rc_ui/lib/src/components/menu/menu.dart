import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class MenuItemWidget extends StatelessWidget {
  const MenuItemWidget({
    super.key,
    required this.title,
    required this.width,
    required this.height,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final double width;
  final double height;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFF001024),
        child: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),
            if (selected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0486, 0.4622, 0.9583],
                      colors: [
                        Color.fromRGBO(0, 114, 255, 0),
                        Color.fromRGBO(0, 114, 255, 1),
                        Color.fromRGBO(0, 114, 255, 0),
                      ],
                    ),
                  ),
                ),
              ),
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: AppFonts.s14,
                  fontWeight: AppFonts.w600,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (!selected) {
      return const ColoredBox(color: Color(0xFF001024));
    }
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.fromRGBO(0, 114, 255, 0.48),
            Color.fromRGBO(0, 115, 255, 0),
          ],
        ),
      ),
    );
  }
}

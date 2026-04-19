
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

Widget iconButton({required IconData icon, required VoidCallback onTap}) {
  final box = AppDimens.compactCell(34);
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: box,
      height: box,
      decoration: BoxDecoration(
        color: const Color(0x661B2D4D),
        borderRadius: BorderRadius.circular(AppDimens.compactCell(8)),
        border: Border.all(color: const Color(0xFF0072FF)),
        boxShadow: const [
          BoxShadow(color: Color(0x660072FF), blurRadius: 4, spreadRadius: -2),
        ],
      ),
      child: Icon(
        icon,
        color: AppColors.primary,
        size: AppDimens.compactIcon(AppDimens.iconS),
      ),
    ),
  );
}

class TechActionTile extends StatelessWidget {
  const TechActionTile({
    super.key,
    required this.title,
    required this.sub,
    required this.icon,
    this.trailing,
    required this.onTap,
  });

  final String title;
  final String sub;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = AppDimens.compactCell(62);
    final px = AppDimens.compactCell(16);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: px),
        decoration: BoxDecoration(
          color: const Color(0x291B2D4D),
          borderRadius: BorderRadius.circular(AppDimens.compactCell(16)),
          border: Border.all(color: const Color(0xFF0072FF), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D0072FF),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: AppFonts.s10,
                  fontWeight: AppFonts.w700,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            SizedBox(width: AppDimens.compactCell(10)),
            const _TileArrow(),
          ],
        ),
      ),
    );
  }
}

class _TileArrow extends StatelessWidget {
  const _TileArrow();

  @override
  Widget build(BuildContext context) {
    final w = AppDimens.compactCell(7);
    final h = AppDimens.compactCell(11);
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(painter: _ArrowPainter()),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, 0);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.335
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF7DA2CE),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

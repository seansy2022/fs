import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 统一承载遥控器应用弹窗的背景、尺寸约束与渐变描边。
class RcDialogShell extends StatelessWidget {
  const RcDialogShell({
    super.key,
    required this.child,
    this.width = 313,
    this.height,
    this.radius = 8,
  });

  final Widget child;
  final double width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final resolvedWidth = math.min(width, screenWidth - 32);
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SizedBox(
          width: resolvedWidth,
          height: height,
          child: CustomPaint(
            foregroundPainter: _DialogBorderPainter(radius: radius),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: ColoredBox(color: const Color(0xFF002149), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogBorderPainter extends CustomPainter {
  const _DialogBorderPainter({required this.radius});

  final double radius;

  /// 绘制与设计稿一致的纵向浅蓝渐变描边。
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        colors: [
          Color(0x667DA2CE),
          Color(0xA37DA2CE),
          Color(0xFF7DA2CE),
          Color(0xA37DA2CE),
          Color(0x667DA2CE),
        ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DialogBorderPainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}

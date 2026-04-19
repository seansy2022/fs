import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'package:rc_ui/src/features/dashboard/top_data.dart';

class TopDrawBase {
  static void draw(Canvas c, double sx, double sy, ui.Image? image) {
    _drawBackground(c, sx, sy, image);
    _drawPaths(c, sx, sy);
    _drawDots(c, sx, sy);
  }

  static void _drawBackground(Canvas c, double sx, double sy, ui.Image? image) {
    c.drawRect(
      Rect.fromLTWH(0, 0, topDesignSize.width * sx, topDesignSize.height * sy),
      Paint()..color = AppColors.bg,
    );
    if (image == null) return;
    final dst = Rect.fromLTWH(
      topImageRect.left * sx,
      topImageRect.top * sy,
      topImageRect.width * sx,
      topImageRect.height * sy,
    );
    final rr = RRect.fromRectAndRadius(
      dst,
      Radius.circular(topImageRadius.x * sx),
    );
    c.save();
    c.clipRRect(rr);
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    c.drawImageRect(image, src, dst, Paint());
    c.restore();
  }

  static void _drawPaths(Canvas c, double sx, double sy) {
    final p = Paint()
      ..color = AppColors.primary
      ..strokeWidth = sx
      ..style = PaintingStyle.stroke;
    for (final points in topPathPoints) {
      final path = Path()..moveTo(points.first.dx * sx, points.first.dy * sy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx * sx, point.dy * sy);
      }
      c.drawPath(path, p);
    }
  }

  static void _drawDots(Canvas c, double sx, double sy) {
    for (final dot in topDots) {
      final offset = Offset(dot.dx * sx, dot.dy * sy);
      final radius = 7.5 * sx;

      // 绘制外圆圈
      final borderPaint = Paint()
        ..color = const Color(0xFF0072FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * sx;
      c.drawCircle(offset, radius, borderPaint);

      // 绘制内圆点
      final fillPaint = Paint()..color = const Color(0xFFEDF5FF);
      c.drawCircle(offset, 4.5 * sx, fillPaint);
    }
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class RateChartPainter extends CustomPainter {
  const RateChartPainter(this.value);

  final int value;
  static const _xLabels = [100, 80, 60, 40, 20, 0, 20, 40, 60, 80, 100];
  static const _yLabels = [100, 80, 60, 40, 20, 0, 20, 40, 60, 80, 100];
  static const _labelStyle = TextStyle(
    color: Color(0xFF465D7A),
    fontSize: AppFonts.s10,
    fontFamily: AppFonts.roboto,
    height: 1,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final plot = _plotRect(size);
    _paintBackground(canvas, plot);
    _paintGrid(canvas, plot);
    _paintCenterAxes(canvas, plot);
    _paintCurve(canvas, plot);
    _paintBorder(canvas, plot);
    _paintAxisLabels(canvas, plot, size);
  }

  Rect _plotRect(Size size) {
    const left = 6.0;
    const top = 6.0;
    const right = 1.0;
    const bottom = 1.0;
    return Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
  }

  void _paintBackground(Canvas canvas, Rect plot) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0x140073FF), Color(0x020072FF)],
      ).createShader(plot);
    canvas.drawRect(plot, paint);
  }

  void _paintGrid(Canvas canvas, Rect plot) {
    final paint = Paint()
      ..color = const Color(0xFF233854)
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 10; i++) {
      final t = i / 10;
      final x = plot.left + plot.width * t;
      final y = plot.top + plot.height * t;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), paint);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), paint);
    }
  }

  void _paintCenterAxes(Canvas canvas, Rect plot) {
    final axis = Paint()
      ..color = const Color(0xFFFF3700)
      ..strokeWidth = 0.1;
    _drawDashedLine(
      canvas,
      Offset(plot.left, plot.center.dy),
      Offset(plot.right, plot.center.dy),
      axis,
    );
    _drawDashedLine(
      canvas,
      Offset(plot.center.dx, plot.top),
      Offset(plot.center.dx, plot.bottom),
      axis,
    );
  }

  void _paintCurve(Canvas canvas, Rect plot) {
    final curve = _firstQuadrantBezier(value.clamp(-100, 100) / 100);
    final left = plot.left + 1;
    final right = plot.right - 1;
    final top = plot.top + 1;
    final bottom = plot.bottom - 1;
    final center = Offset((left + right) / 2, (top + bottom) / 2);
    final halfW = (right - left) / 2;
    final halfH = (bottom - top) / 2;
    final start = Offset(left, bottom);
    final end = Offset(right, top);
    final c1Q1 = Offset(
      center.dx + curve.$1.dx * halfW,
      center.dy - curve.$1.dy * halfH,
    );
    final c2Q1 = Offset(
      center.dx + curve.$2.dx * halfW,
      center.dy - curve.$2.dy * halfH,
    );
    final c1Q3 = Offset(
      center.dx - curve.$2.dx * halfW,
      center.dy + curve.$2.dy * halfH,
    );
    final c2Q3 = Offset(
      center.dx - curve.$1.dx * halfW,
      center.dy + curve.$1.dy * halfH,
    );
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1Q3.dx, c1Q3.dy, c2Q3.dx, c2Q3.dy, center.dx, center.dy)
      ..cubicTo(c1Q1.dx, c1Q1.dy, c2Q1.dx, c2Q1.dy, end.dx, end.dy);
    final paint = Paint()
      ..color = const Color(0xFF00C6FF)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  (Offset, Offset) _firstQuadrantBezier(double ratio) {
    const base = 0.44;
    const line = (Offset(1 / 3, 1 / 3), Offset(2 / 3, 2 / 3));
    const positive = (Offset(0, base), Offset(base, 1));
    const negative = (Offset(1 - base, 0), Offset(1, 1 - base));
    final target = ratio >= 0 ? positive : negative;
    final t = ratio.abs().clamp(0.0, 1.0);
    final c1 = Offset(
      _lerp(line.$1.dx, target.$1.dx, t),
      _lerp(line.$1.dy, target.$1.dy, t),
    );
    final c2 = Offset(
      _lerp(line.$2.dx, target.$2.dx, t),
      _lerp(line.$2.dy, target.$2.dy, t),
    );
    return (c1, c2);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _paintBorder(Canvas canvas, Rect plot) {
    final paint = Paint()
      ..color = const Color(0xFF7DA2CE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1;
    canvas.drawRect(plot, paint);
  }

  void _paintAxisLabels(Canvas canvas, Rect plot, Size size) {
    _paintXLabels(canvas, plot, size);
    _paintYLabels(canvas, plot, size);
  }

  void _paintXLabels(Canvas canvas, Rect plot, Size size) {
    final step = _xLabels.length - 1;
    for (var i = 0; i < _xLabels.length; i++) {
      final tp = _label(_xLabels[i].toString());
      var tx = plot.left + plot.width * (i / step) - tp.width / 2;
      final ty = plot.bottom + 4;
      // 限制水平边界：不能超过左边和右边
      tx = tx.clamp(4, size.width - tp.width);
      tp.paint(canvas, Offset(tx, ty));
    }
  }

  void _paintYLabels(Canvas canvas, Rect plot, Size size) {
    final step = _yLabels.length - 1;
    for (var i = 0; i < _yLabels.length; i++) {
      final tp = _label(_yLabels[i].toString());
      final lx = plot.left - tp.width - 4;
      var ly = plot.top + plot.height * (i / step) - tp.height / 2;
      // 限制垂直边界：不能超过上边和下边，留出一点边距
      ly = ly.clamp(4, size.height - tp.height - 2);
      tp.paint(canvas, Offset(lx, ly));
    }
  }

  TextPainter _label(String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    tp.layout();
    return tp;
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final distance = (end - start).distance;
    final delta = (end - start) / distance;
    const dash = 3.0;
    const gap = 3.0;
    var offset = 0.0;
    while (offset < distance) {
      final dashEnd = math.min(offset + dash, distance);
      canvas.drawLine(start + delta * offset, start + delta * dashEnd, paint);
      offset += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant RateChartPainter oldDelegate) =>
      oldDelegate.value != value;
}


import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

import 'package:rc_ui/src/features/dashboard/top_data.dart';

class TopDrawNodes {
  static const _nodeScale = 1;

  static void draw(Canvas c, double sx, double sy, String selectedChannel) {
    for (final node in topChannelNodes) {
      _drawNode(c, sx, sy, node, node.id == selectedChannel);
    }
  }

  static void _drawNode(
    Canvas c,
    double sx,
    double sy,
    TopChannelNode n,
    bool selected,
  ) {
    final baseRect = Rect.fromLTWH(
      n.rect.left * sx,
      n.rect.top * sy,
      n.rect.width * sx,
      n.rect.height * sy,
    );
    final rect = _scaledRect(baseRect);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(4 * sx));
    _fillNode(c, rr, rect, selected);
    _drawBorder(c, rr, sx, selected);
    _drawLabel(c, rect, n.id, sx);
  }

  static Rect _scaledRect(Rect rect) {
    final dx = rect.width * (1 - _nodeScale) / 2;
    final dy = rect.height * (1 - _nodeScale) / 2;
    return Rect.fromLTRB(
      rect.left + dx,
      rect.top + dy,
      rect.right - dx,
      rect.bottom - dy,
    );
  }

  static void _fillNode(Canvas c, RRect rr, Rect rect, bool selected) {
    c.drawRRect(rr, Paint()..color = const Color(0x661B2D4D));
    if (!selected) return;
    final shader = const LinearGradient(
      colors: [Color(0x0000C6FF), Color(0x8000C6FF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(rect);
    c.drawRRect(rr, Paint()..shader = shader);
  }

  static void _drawBorder(Canvas c, RRect rr, double sx, bool selected) {
    c.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * sx
        ..color = selected ? const Color(0xFF00C6FF) : AppColors.primary,
    );
  }

  static void _drawLabel(Canvas c, Rect rect, String id, double sx) {
    final tp = TextPainter(
      text: TextSpan(
        text: id,
        style: TextStyle(
          color: AppColors.text,
          fontSize: AppFonts.s14,
          fontFamily: AppFonts.roboto,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      c,
      Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
    );
  }
}

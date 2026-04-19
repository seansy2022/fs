import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';
import 'blue_loading_base.dart';

class BlueConnectSuccessLoading extends StatelessWidget {
  const BlueConnectSuccessLoading({
    super.key,
    this.text = '设备连接成功!',
    this.progress = 1,
  });

  final String text;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0).toDouble();
    return BlueLoadingBase(
      text: text,
      middle: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(60),
              painter: _SuccessRingPainter(progress: normalizedProgress),
            ),
            SizedBox(
              width: 17,
              height: 11,
              child: CustomPaint(painter: _SuccessCheckPainter()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessRingPainter extends CustomPainter {
  const _SuccessRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF1B2D4D);
    canvas.drawCircle(center, radius, base);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF17D37A);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _SuccessRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SuccessCheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 37.0;
    final scaleY = size.height / 26.0;
    final strokeScale = math.min(scaleX, scaleY);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * strokeScale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF67E600);
    final path = Path()
      ..moveTo(2 * scaleX, 13.0002 * scaleY)
      ..lineTo(13.0002 * scaleX, 24.0005 * scaleY)
      ..lineTo(35.0007 * scaleX, 2 * scaleY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';
import 'blue_loading_base.dart';

class BlueConnectFailLoading extends StatelessWidget {
  const BlueConnectFailLoading({
    super.key,
    this.text = '设备连接失败!',
    this.progress = 0,
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
              painter: _FailRingPainter(progress: normalizedProgress),
            ),
            SizedBox(
              width: 13,
              height: 13,
              child: CustomPaint(painter: _FailCenterSlashPainter()),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailRingPainter extends CustomPainter {
  const _FailRingPainter({required this.progress});

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
      ..color = const Color(0xFFFF3700);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _FailRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _FailCenterSlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 48.0;
    final scaleY = size.height / 48.0;
    final strokeScale = math.min(scaleX, scaleY);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * strokeScale
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF3700);
    final path1 = Path()
      ..moveTo(11.1978 * scaleX, 36.8028 * scaleY)
      ..lineTo(36.8032 * scaleX, 11.1974 * scaleY);
    final path2 = Path()
      ..moveTo(36.9997 * scaleX, 37.0002 * scaleY)
      ..lineTo(11.0 * scaleX, 11.0005 * scaleY);
    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

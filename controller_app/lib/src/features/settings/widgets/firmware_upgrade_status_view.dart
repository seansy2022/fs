import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

enum FirmwareUpgradeVisualState { loading, success, failure }

class FirmwareUpgradeStatusView extends StatelessWidget {
  const FirmwareUpgradeStatusView({
    super.key,
    required this.state,
    required this.progress,
    this.failureMessage = '请检查设备状态后再试！',
  });

  static const loadingColor = Color(0xFF00C6FF);
  static const successColor = Color(0xFF67E600);
  static const failureColor = Color(0xFFFF3700);
  static const inactiveColor = Color(0xFF1B2D4D);

  final FirmwareUpgradeVisualState state;
  final int progress;
  final String failureMessage;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      FirmwareUpgradeVisualState.loading => loadingColor,
      FirmwareUpgradeVisualState.success => successColor,
      FirmwareUpgradeVisualState.failure => failureColor,
    };
    return SizedBox(
      width: 236,
      height: state == FirmwareUpgradeVisualState.failure ? 156 : 132,
      child: Column(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(90),
                  painter: _SegmentProgressPainter(
                    progress: (progress / 100).clamp(0, 1),
                    activeColor: color,
                    inactiveColor: inactiveColor,
                  ),
                ),
                _CenterContent(state: state, progress: progress, color: color),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            switch (state) {
              FirmwareUpgradeVisualState.loading => '固件更新中…',
              FirmwareUpgradeVisualState.success => '固件更新成功！',
              FirmwareUpgradeVisualState.failure => '更新失败！',
            },
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: AppFonts.w600,
            ),
          ),
          if (state == FirmwareUpgradeVisualState.failure) ...[
            const SizedBox(height: 8),
            Text(
              failureMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7DA2CE), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _CenterContent extends StatelessWidget {
  const _CenterContent({
    required this.state,
    required this.progress,
    required this.color,
  });

  final FirmwareUpgradeVisualState state;
  final int progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      FirmwareUpgradeVisualState.loading => Text(
        '$progress%',
        style: TextStyle(color: color, fontSize: 16, fontWeight: AppFonts.w600),
      ),
      FirmwareUpgradeVisualState.success => Icon(
        Icons.check,
        color: color,
        size: 26,
      ),
      FirmwareUpgradeVisualState.failure => Icon(
        Icons.close,
        color: color,
        size: 24,
      ),
    };
  }
}

class _SegmentProgressPainter extends CustomPainter {
  const _SegmentProgressPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    const segmentCount = 20;
    const segmentScale = 0.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final litCount = (segmentCount * progress).ceil();
    final segmentPath = _buildSegmentPath();

    for (var i = 0; i < segmentCount; i++) {
      final angle = -math.pi / 2 + (2 * math.pi / segmentCount) * i;
      final segmentCenter = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final paint = Paint()
        ..color = i < litCount ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(segmentCenter.dx, segmentCenter.dy);
      canvas.rotate(angle + math.pi / 2);
      canvas.scale(segmentScale, segmentScale);
      canvas.drawPath(segmentPath, paint);
      canvas.restore();
    }
  }

  Path _buildSegmentPath() {
    const width = 11.99951171875;
    const height = 19.99951171875;
    final centerX = width / 2;
    final centerY = height / 2;
    return Path()
      ..moveTo(0 - centerX, 0 - centerY)
      ..lineTo(11.9996 - centerX, 0 - centerY)
      ..lineTo(9.99967 - centerX, 19.9993 - centerY)
      ..lineTo(1.99993 - centerX, 19.9993 - centerY)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _SegmentProgressPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        activeColor != oldDelegate.activeColor ||
        inactiveColor != oldDelegate.inactiveColor;
  }
}

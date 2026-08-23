import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';
import 'package:controller_app/src/core/localization/app_localizations.dart';

/// 首页自动重连期间展示的接收机配对提示弹窗。
class HomeReconnectDialog extends StatelessWidget {
  const HomeReconnectDialog({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  /// 构建与首页尺寸适配的配对提示卡片。
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width - 32;
    return Container(
      width: math.min(343, availableWidth),
      height: 236,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2D4D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Row(
              children: [
                const SizedBox(width: 44),
                Expanded(
                  child: Center(
                    child: Text(
                      AppText.tr('配对接收机'),
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: AppFonts.s18,
                        fontWeight: AppFonts.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.cancel_outlined, size: 24),
                    color: const Color(0xFF7DA2CE),
                    tooltip: AppText.tr('取消配对'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFF233854)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PairingSpinner(),
                SizedBox(height: 20),
                Text(
                  AppText.tr('正在配对，请确认接收机处于蓝牙模式\n（LED灯常亮2秒灭一秒）'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PairingSpinner extends StatefulWidget {
  const _PairingSpinner();

  @override
  State<_PairingSpinner> createState() => _PairingSpinnerState();
}

class _PairingSpinnerState extends State<_PairingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  /// 构建持续旋转的分段加载图标。
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: const Size.square(60),
        painter: const _SegmentedSpinnerPainter(),
      ),
    );
  }
}

class _SegmentedSpinnerPainter extends CustomPainter {
  const _SegmentedSpinnerPainter();

  @override
  /// 绘制与设计稿一致的十二段渐变蓝色加载环。
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const segmentCount = 12;
    final segmentPaint = Paint()..color = const Color(0xFF0072FF);

    for (var index = 0; index < segmentCount; index++) {
      final opacity = 0.16 + (index / (segmentCount - 1)) * 0.76;
      segmentPaint.color = const Color(0xFF0072FF).withValues(alpha: opacity);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(math.pi * 2 * index / segmentCount);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, -23), width: 6, height: 14),
          const Radius.circular(2),
        ),
        segmentPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedSpinnerPainter oldDelegate) => false;
}

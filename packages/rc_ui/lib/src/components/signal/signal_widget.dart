import 'package:flutter/material.dart';

// ── ViewBox constants (from reference SVG: 58×32) ──────────────────────────────
const _vbW = 58.0;
const _vbH = 32.0;
const _barRadius = 3.0;

// Each bar: (left, top, width, height) in viewBox coordinates
const _signalBars = [
  _BarData(0.0, 21.0, 10.0, 11.0),
  _BarData(16.0, 15.0, 10.0, 17.0),
  _BarData(32.0, 9.0, 10.0, 23.0),
  _BarData(48.0, 3.0, 10.0, 29.0),
];

class _BarData {
  const _BarData(this.left, this.top, this.width, this.height);
  final double left, top, width, height;
}

// ── Default colors ─────────────────────────────────────────────────────────────
const _kActiveColor = Color(0xFF67E600);
const _kInactiveColor = Color(0x3DEDF5FF); // rgba(237,245,255,0.24)

/// 信号强度指示器
class SignalWidget extends StatelessWidget {
  const SignalWidget({
    super.key,
    required this.value,
    this.width,
    this.height,
    this.activeColor,
    this.inactiveColor,
  });

  /// 信号强度（0–100），映射到 0–4 格
  final double value;

  /// 宽度（默认 29.0，为 SVG viewBox 宽度的一半）
  final double? width;

  /// 高度（默认 16.0，为 SVG viewBox 高度的一半）
  final double? height;

  /// 信号满格颜色
  final Color? activeColor;

  /// 信号空格颜色
  final Color? inactiveColor;

  int _activeBars() {
    final v = value.clamp(0.0, 100.0);
    if (v > 75) return 4;
    if (v > 50) return 3;
    if (v > 25) return 2;
    if (v > 0) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 29.0,
      height: height ?? 16.0,
      child: CustomPaint(
        painter: _SignalPainter(
          activeBars: _activeBars(),
          activeColor: activeColor ?? _kActiveColor,
          inactiveColor: inactiveColor ?? _kInactiveColor,
        ),
      ),
    );
  }
}

class _SignalPainter extends CustomPainter {
  const _SignalPainter({
    required this.activeBars,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int activeBars;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _vbW;
    final sy = size.height / _vbH;
    final s = sx < sy ? sx : sy;

    for (var i = 0; i < _signalBars.length; i++) {
      final bar = _signalBars[i];
      final color = i < activeBars ? activeColor : inactiveColor;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          bar.left * sx,
          bar.top * sy,
          bar.width * sx,
          bar.height * sy,
        ),
        Radius.circular(_barRadius * s),
      );

      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SignalPainter oldDelegate) {
    return oldDelegate.activeBars != activeBars ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

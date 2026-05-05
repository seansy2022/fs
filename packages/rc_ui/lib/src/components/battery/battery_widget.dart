import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

// ── ViewBox constants (from reference SVG: 68×34) ──────────────────────────────
const _vbW = 68.0;
const _vbH = 34.0;
const _bodyL = 2.0, _bodyT = 2.0, _bodyR = 59.0, _bodyB = 32.0;
const _bodyRx = 3.0;
const _termL = 63.0, _termT = 11.0, _termR = 68.0, _termB = 23.0;
const _termRx = 1.5;
const _fillPad = 2.0;

// ── Default colors ─────────────────────────────────────────────────────────────
const _kFillGreen = Color(0xFF67E600);
const _kFillRed = Color(0xFFFF3B30);
const _kOutlineDefault = Color(0x7AEDF5FF); // rgba(237,245,255,0.48)
const _kBackgroundDefault = Color(0x1A001024);

/// 电池电量指示器
class BatteryWidget extends StatelessWidget {
  const BatteryWidget({
    super.key,
    required this.value,
    this.width,
    this.height,
    this.fillColor,
    this.lowBatteryColor,
    this.criticalBatteryColor,
    this.outlineColor,
    this.backgroundColor,
    this.showTerminal = true,
    this.lowBatteryThreshold = 20,
    this.criticalBatteryThreshold = 10,
  });

  /// 电池电量百分比（0–100），超出范围会被钳制
  final double value;

  /// 宽度（默认 34.0，为 SVG viewBox 宽度的一半）
  final double? width;

  /// 高度（默认 17.0，为 SVG viewBox 高度的一半）
  final double? height;

  /// 正常电量区间的填充色（> [lowBatteryThreshold]）
  final Color? fillColor;

  /// 低电量区间的填充色
  final Color? lowBatteryColor;

  /// 严重低电量区间的填充色
  final Color? criticalBatteryColor;

  /// 电池外壳描边颜色
  final Color? outlineColor;

  /// 电池内部背景色（填充条后方的底色）
  final Color? backgroundColor;

  /// 是否显示电池头
  final bool showTerminal;

  /// 低电量阈值（含），低于此值使用 [lowBatteryColor]
  final double lowBatteryThreshold;

  /// 严重低电量阈值（含），低于此值使用 [criticalBatteryColor]
  final double criticalBatteryThreshold;

  Color _resolveFillColor(double v) {
    if (v <= criticalBatteryThreshold) {
      return criticalBatteryColor ?? _kFillRed;
    } else if (v <= lowBatteryThreshold) {
      return lowBatteryColor ?? AppColors.tertiary;
    }
    return fillColor ?? _kFillGreen;
  }

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 100.0);
    return SizedBox(
      width: width ?? 34.0,
      height: height ?? 17.0,
      child: CustomPaint(
        painter: _BatteryPainter(
          value: clamped,
          fillColor: _resolveFillColor(clamped),
          outlineColor: outlineColor ?? _kOutlineDefault,
          backgroundColor: backgroundColor ?? _kBackgroundDefault,
          showTerminal: showTerminal,
        ),
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter({
    required this.value,
    required this.fillColor,
    required this.outlineColor,
    required this.backgroundColor,
    required this.showTerminal,
  });

  final double value;
  final Color fillColor;
  final Color outlineColor;
  final Color backgroundColor;
  final bool showTerminal;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _vbW;
    final sy = size.height / _vbH;
    final s = sx < sy ? sx : sy;

    _drawBackground(canvas, sx, sy, s);
    _drawFill(canvas, sx, sy, s);
    _drawBodyOutline(canvas, sx, sy, s);
    if (showTerminal) {
      _drawTerminal(canvas, sx, sy, s);
    }
  }

  void _drawBackground(Canvas canvas, double sx, double sy, double s) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (_bodyL + _fillPad) * sx,
        (_bodyT + _fillPad) * sy,
        (_bodyR - _bodyL - 2 * _fillPad) * sx,
        (_bodyB - _bodyT - 2 * _fillPad) * sy,
      ),
      Radius.circular((_bodyRx - _fillPad).clamp(0, double.infinity) * s),
    );
    canvas.drawRRect(rrect, Paint()..color = backgroundColor);
  }

  void _drawFill(Canvas canvas, double sx, double sy, double s) {
    final maxFillW = (_bodyR - _bodyL - 2 * _fillPad) * sx;
    final fillW = maxFillW * (value / 100.0);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (_bodyL + _fillPad) * sx,
        (_bodyT + _fillPad) * sy,
        fillW,
        (_bodyB - _bodyT - 2 * _fillPad) * sy,
      ),
      Radius.circular((_bodyRx - _fillPad).clamp(0, double.infinity) * s),
    );
    canvas.drawRRect(rrect, Paint()..color = fillColor);
  }

  void _drawBodyOutline(Canvas canvas, double sx, double sy, double s) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _bodyL * sx,
        _bodyT * sy,
        (_bodyR - _bodyL) * sx,
        (_bodyB - _bodyT) * sy,
      ),
      Radius.circular(_bodyRx * s),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawTerminal(Canvas canvas, double sx, double sy, double s) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _termL * sx,
        _termT * sy,
        (_termR - _termL) * sx,
        (_termB - _termT) * sy,
      ),
      Radius.circular(_termRx * s),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.showTerminal != showTerminal;
  }
}

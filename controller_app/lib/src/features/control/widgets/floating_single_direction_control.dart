import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 单向浮动控件的移动轴。
enum FloatingControlAxis { horizontal, vertical }

/// 隐藏双手布局的单向半控件；只显示并输出指定方向。
class FloatingSingleDirectionControl extends StatefulWidget {
  const FloatingSingleDirectionControl({
    super.key,
    required this.axis,
    required this.positive,
    required this.onChanged,
  });

  final FloatingControlAxis axis;
  final bool positive;
  final ValueChanged<double> onChanged;

  @override
  State<FloatingSingleDirectionControl> createState() =>
      _FloatingSingleDirectionControlState();
}

class _FloatingSingleDirectionControlState
    extends State<FloatingSingleDirectionControl> {
  static const _arrowSize = 100.0;
  static const _thumbSize = 44.0;
  static const _travel = 76.0;
  static const _activeAsset = 'packages/rc_ui/lib/src/assets/assets/点击.svg';
  static const _thumbAsset = 'packages/rc_ui/lib/src/assets/assets/手柄点.svg';
  Offset? _origin;
  double _value = 0;

  /// 返回当前箭头与小圆点共同使用的单向移动向量。
  Offset get _direction => switch ((widget.axis, widget.positive)) {
    (FloatingControlAxis.horizontal, true) => const Offset(1, 0),
    (FloatingControlAxis.horizontal, false) => const Offset(-1, 0),
    (FloatingControlAxis.vertical, true) => const Offset(0, -1),
    (FloatingControlAxis.vertical, false) => const Offset(0, 1),
  };

  /// 将零位点限制在触控面内，给箭头向前延伸和小圆点自身预留空间。
  Offset _clampOrigin(Offset raw, Size size) {
    final direction = _direction;
    final radius = _thumbSize / 2;
    return Offset(
      _clampAxis(raw.dx, size.width, direction.dx, radius),
      _clampAxis(raw.dy, size.height, direction.dy, radius),
    );
  }

  /// 按单向箭头的延伸方向计算坐标轴的合法零位范围。
  double _clampAxis(
    double raw,
    double extent,
    double direction,
    double radius,
  ) {
    final before = direction < 0 ? _arrowSize : radius;
    final after = direction > 0 ? _arrowSize : radius;
    if (extent <= before + after) return extent / 2;
    return raw.clamp(before, extent - after).toDouble();
  }

  /// 按下时显示单向箭头并以按下点建立本次手势原点。
  void _start(Offset position, Size size) {
    setState(() {
      _origin = _clampOrigin(position, size);
      _value = 0;
    });
    widget.onChanged(0);
  }

  /// 仅接受箭头指向的位移，另一方向始终保持中位输出。
  void _update(Offset position) {
    final origin = _origin;
    if (origin == null) return;
    final delta = widget.axis == FloatingControlAxis.horizontal
        ? position.dx - origin.dx
        : origin.dy - position.dy;
    final directional = widget.positive ? delta : -delta;
    final magnitude = (directional / _travel).clamp(0, 1).toDouble();
    final value = widget.positive ? magnitude : -magnitude;
    setState(() => _value = value);
    widget.onChanged(value);
  }

  /// 结束或取消手势时隐藏控件并让对应通道回中。
  void _reset() {
    if (_origin != null) setState(() => _origin = null);
    widget.onChanged(0);
  }

  double get _angle => switch ((widget.axis, widget.positive)) {
    (FloatingControlAxis.horizontal, true) => 0,
    (FloatingControlAxis.horizontal, false) => math.pi,
    (FloatingControlAxis.vertical, true) => -math.pi / 2,
    (FloatingControlAxis.vertical, false) => math.pi / 2,
  };

  /// 箭头从小圆点的零位向允许方向延伸，避免零位圆点压在箭头中心。
  Offset _arrowCenter(Offset origin) {
    final direction = _direction;
    return origin + direction * (_arrowSize / 2);
  }

  /// 小圆点从按下零位沿箭头方向移动，移动距离与输出比例一致。
  Offset _thumbCenter(Offset origin) =>
      origin + _direction * _value.abs() * _travel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final origin = _origin;
        final arrowCenter = origin == null ? null : _arrowCenter(origin);
        final thumbCenter = origin == null ? null : _thumbCenter(origin);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) =>
              _start(details.localPosition, constraints.biggest),
          onPanUpdate: (details) => _update(details.localPosition),
          onPanEnd: (_) => _reset(),
          onPanCancel: _reset,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (origin != null) ...[
                Positioned(
                  left: arrowCenter!.dx - _arrowSize / 2,
                  top: arrowCenter.dy - _arrowSize / 2,
                  width: _arrowSize,
                  height: _arrowSize,
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: _angle,
                      child: SvgPicture.asset(
                        _activeAsset,
                        key: ValueKey<String>(
                          'floating-single-arrow-${widget.axis.name}-${widget.positive}',
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: thumbCenter!.dx - _thumbSize / 2,
                  top: thumbCenter.dy - _thumbSize / 2,
                  width: _thumbSize,
                  height: _thumbSize,
                  child: IgnorePointer(
                    child: SvgPicture.asset(
                      _thumbAsset,
                      key: const ValueKey<String>('floating-single-thumb'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

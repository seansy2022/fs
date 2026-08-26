import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'four_direction_control.dart';

const floatingFourDirectionThumbKey = ValueKey<String>(
  'floating-four-direction-thumb',
);

/// 单手隐藏可变二维控制区；按下位置为本次方向与油门的共同原点。
class FloatingFourDirectionControl extends StatefulWidget {
  const FloatingFourDirectionControl({super.key, required this.onChanged});

  final ValueChanged<FourDirectionValue> onChanged;

  @override
  State<FloatingFourDirectionControl> createState() =>
      _FloatingFourDirectionControlState();
}

class _FloatingFourDirectionControlState
    extends State<FloatingFourDirectionControl> {
  static const _side = singleHandControlSide;
  static const _thumb = 44.0;
  Offset? _origin;
  Offset _value = Offset.zero;

  /// 将控件中心限制在操控面内，避免四方向视觉被屏幕边缘裁切。
  Offset _clampOrigin(Offset raw, Size size) {
    final half = math.min(_side / 2, math.min(size.width, size.height) / 2);
    return Offset(
      raw.dx.clamp(half, size.width - half).toDouble(),
      raw.dy.clamp(half, size.height - half).toDouble(),
    );
  }

  /// 按下时仅记录原点并显示控件，输出保持在中位。
  void _start(Offset position, Size size) {
    setState(() {
      _origin = _clampOrigin(position, size);
      _value = Offset.zero;
    });
    widget.onChanged(const FourDirectionValue(steering: 0, throttle: 0));
  }

  /// 将相对原点的二维位移映射到 -1 至 1 的方向与油门值。
  void _update(Offset position) {
    final origin = _origin;
    if (origin == null) return;
    final travel = (_side - _thumb) / 2;
    final value = Offset(
      ((position.dx - origin.dx) / travel).clamp(-1, 1).toDouble(),
      (-(position.dy - origin.dy) / travel).clamp(-1, 1).toDouble(),
    );
    setState(() => _value = value);
    widget.onChanged(
      FourDirectionValue(steering: value.dx, throttle: value.dy),
    );
  }

  /// 手势结束时清空视觉与两个通道输出。
  void _reset() {
    if (_origin != null) setState(() => _origin = null);
    widget.onChanged(const FourDirectionValue(steering: 0, throttle: 0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final origin = _origin;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) => _start(details.localPosition, size),
          onPanUpdate: (details) => _update(details.localPosition),
          onPanEnd: (_) => _reset(),
          onPanCancel: _reset,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (origin != null) ...[
                Positioned(
                  left: origin.dx - _side / 2,
                  top: origin.dy - _side / 2,
                  width: _side,
                  height: _side,
                  child: IgnorePointer(
                    child: FourDirectionControl(onChanged: (_) {}),
                  ),
                ),
                Positioned(
                  key: floatingFourDirectionThumbKey,
                  left:
                      origin.dx +
                      _value.dx * ((_side - _thumb) / 2) -
                      _thumb / 2,
                  top:
                      origin.dy -
                      _value.dy * ((_side - _thumb) / 2) -
                      _thumb / 2,
                  width: _thumb,
                  height: _thumb,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFEDF5FF),
                      shape: BoxShape.circle,
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

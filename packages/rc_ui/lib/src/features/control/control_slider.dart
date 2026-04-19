import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

const _kControlWidth = 100.0;
const _kControlHeight = 206.0;
const _kClickButtonSvgAsset = 'packages/rc_ui/lib/src/assets/assets/点击.svg';

const _kThumbSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="88" height="88" viewBox="0 0 88 88" fill="none">
  <ellipse cx="44" cy="44" rx="44" ry="44" fill="#EDF5FF"/>
  <circle cx="44" cy="44" r="33" fill="#EDF5FF"/>
  <path fill-rule="evenodd" fill="rgba(0, 16, 36, 1)" d="M44 77C62.2254 77 77 62.2254 77 44C77 25.7746 62.2254 11 44 11C25.7746 11 11 25.7746 11 44C11 62.2254 25.7746 77 44 77ZM44 13C61.1208 13 75 26.8792 75 44C75 61.1208 61.1208 75 44 75C26.8792 75 13 61.1208 13 44C13 26.8792 26.8792 13 44 13Z"/>
</svg>
''';

/// 控制手柄方向
enum ControlSliderDirection { vertical, horizontal }

/// 控制手柄组件
/// 支持垂直和水平两种模式
/// 手柄点默认在中间，可以移动，松手后回到原位置
class ControlSlider extends StatefulWidget {
  const ControlSlider({
    super.key,
    required this.direction,
    required this.onChanged,
    double? width,
    double? height,
    this.thumbSize = 44,
  }) : width =
           width ??
           (direction == ControlSliderDirection.vertical
               ? _kControlWidth
               : _kControlHeight),
       height =
           height ??
           (direction == ControlSliderDirection.vertical
               ? _kControlHeight
               : _kControlWidth);

  /// 方向：垂直或水平
  final ControlSliderDirection direction;

  /// 值变化回调，范围 -100 到 100，中间为 0
  final ValueChanged<int> onChanged;

  /// 宽度（默认：垂直100，水平206）
  final double width;

  /// 高度（默认：垂直206，水平100）
  final double height;

  /// 手柄点大小
  final double thumbSize;

  @override
  State<ControlSlider> createState() => _ControlSliderState();
}

class _ControlSliderState extends State<ControlSlider> {
  double _value = 0; // -100 到 100

  void _updateValue(Offset localPosition) {
    final isVertical = widget.direction == ControlSliderDirection.vertical;
    double newValue;

    if (isVertical) {
      // 垂直方向：顶部为 100，底部为 -100
      final range = widget.height - widget.thumbSize;
      final center = range / 2;
      final position = localPosition.dy - widget.thumbSize / 2;
      newValue = ((center - position) / center * 100).clamp(-100.0, 100.0);
    } else {
      // 水平方向：左侧为 -100，右侧为 100
      final range = widget.width - widget.thumbSize;
      final center = range / 2;
      final position = localPosition.dx - widget.thumbSize / 2;
      newValue = ((position - center) / center * 100).clamp(-100.0, 100.0);
    }

    if (newValue != _value) {
      setState(() => _value = newValue);
      widget.onChanged(newValue.round());
    }
  }

  void _reset() {
    if (_value != 0) {
      setState(() => _value = 0);
      widget.onChanged(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = widget.direction == ControlSliderDirection.vertical;

    return GestureDetector(
      onPanStart: (details) => _updateValue(details.localPosition),
      onPanUpdate: (details) => _updateValue(details.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 垂直方向：上面的点击按钮（旋转-90度）
            if (isVertical)
              Positioned(
                top: 0,
                child: SizedBox(
                  width: widget.width,
                  height: widget.width,
                  child: Transform.rotate(
                    angle: -math.pi / 2, // -90度
                    child: SvgPicture.asset(
                      _kClickButtonSvgAsset,
                      width: widget.width,
                      height: widget.width,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            // 垂直方向：下面的点击按钮（旋转90度）
            if (isVertical)
              Positioned(
                bottom: 0,
                child: SizedBox(
                  width: widget.width,
                  height: widget.width,
                  child: Transform.rotate(
                    angle: math.pi / 2, // 90度
                    child: SvgPicture.asset(
                      _kClickButtonSvgAsset,
                      width: widget.width,
                      height: widget.width,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            // 水平方向：左边的点击按钮（旋转-180度）
            if (!isVertical)
              Positioned(
                left: 0,
                top: 0,
                child: SizedBox(
                  width: widget.height,
                  height: widget.height,
                  child: Transform.rotate(
                    angle: -math.pi, // -180度
                    child: SvgPicture.asset(
                      _kClickButtonSvgAsset,
                      width: widget.height,
                      height: widget.height,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            // 水平方向：右边的点击按钮（不旋转）
            if (!isVertical)
              Positioned(
                right: widget.width - widget.height, // 右边位置 = 总宽度 - SVG宽度
                top: 0,
                child: SizedBox(
                  width: widget.height,
                  height: widget.height,
                  child: SvgPicture.asset(
                    _kClickButtonSvgAsset,
                    width: widget.height,
                    height: widget.height,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            // 手柄点
            _buildThumb(isVertical),
          ],
        ),
      ),
    );
  }

  // Widget _buildTrack(bool isVertical) {
  //   return Container(
  //     width: isVertical ? _kControlWidth : widget.width,
  //     height: isVertical ? widget.height : _kControlWidth,
  //     decoration: BoxDecoration(
  //       color: AppColors.surfaceHighest.withValues(alpha: 0.3),
  //       borderRadius: BorderRadius.circular(isVertical ? 50 : 50),
  //     ),
  //     child: CustomPaint(
  //       painter: _TrackPainter(value: _value, isVertical: isVertical),
  //     ),
  //   );
  // }

  Widget _buildThumb(bool isVertical) {
    double left, top;

    if (isVertical) {
      final range = widget.height - widget.thumbSize;
      final center = range / 2;
      top = center - (_value / 100 * center);
      left = (widget.width - widget.thumbSize) / 2;
    } else {
      final range = widget.width - widget.thumbSize;
      final center = range / 2;
      left = center + (_value / 100 * center);
      top = (widget.height - widget.thumbSize) / 2;
    }

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: widget.thumbSize,
        height: widget.thumbSize,
        child: SvgPicture.string(
          _kThumbSvg,
          width: widget.thumbSize,
          height: widget.thumbSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({required this.value, required this.isVertical});

  final double value;
  final bool isVertical;

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制中心线
    final centerPaint = Paint()
      ..color = AppColors.outline
      ..strokeWidth = 1;

    if (isVertical) {
      final centerX = size.width / 2;
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, size.height),
        centerPaint,
      );
    } else {
      final centerY = size.height / 2;
      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        centerPaint,
      );
    }

    // 绘制活动区域
    if (value.abs() > 0) {
      final activePaint = Paint()
        ..shader = LinearGradient(
          begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
          end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
          colors: const [Color(0xFF00C6FF), Color(0xFF92FE9D)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      if (isVertical) {
        final centerY = size.height / 2;
        final thumbY = centerY - (value / 100 * centerY);
        canvas.drawLine(
          Offset(size.width / 2, centerY),
          Offset(size.width / 2, thumbY),
          activePaint..strokeWidth = 3,
        );
      } else {
        final centerX = size.width / 2;
        final thumbX = centerX + (value / 100 * centerX);
        canvas.drawLine(
          Offset(centerX, size.height / 2),
          Offset(thumbX, size.height / 2),
          activePaint..strokeWidth = 3,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

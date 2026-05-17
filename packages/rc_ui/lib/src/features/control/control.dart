import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _kControlWidth = 100.0;
const _kControlHeight = 206.0;
const _kClickButtonActiveSvgAsset =
    'packages/rc_ui/lib/src/assets/assets/\u70b9\u51fb.svg';
const _kClickButtonInactiveSvgAsset =
    'packages/rc_ui/lib/src/assets/assets/\u70b9\u51fb_wei.svg';

const controlThumbKey = ValueKey<String>('control-thumb');
const controlPositiveKey = ValueKey<String>('control-positive');
const controlNegativeKey = ValueKey<String>('control-negative');

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
class Control extends StatefulWidget {
  const Control({
    super.key,
    required this.direction,
    required this.onChanged,
    double? width,
    double? height,
    this.thumbSize = 44,
    this.allowPositive = true,
    this.allowNegative = true,
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

  /// 是否允许正方向（水平向右 / 垂直向上）
  final bool allowPositive;

  /// 是否允许负方向（水平向左 / 垂直向下）
  final bool allowNegative;

  @override
  State<Control> createState() => _ControlState();
}

class _ControlState extends State<Control> {
  static const _epsilon = 0.0001;

  double _value = 0; // [-100, 100]
  bool _isDragging = false;

  bool get _isVertical => widget.direction == ControlSliderDirection.vertical;

  double get _maxTravel {
    final axisExtent = _isVertical ? widget.height : widget.width;
    return (axisExtent - widget.thumbSize) / 2;
  }

  void _updateValue(Offset localPosition) {
    final center = Offset(widget.width / 2, widget.height / 2);
    final axisDelta = _isVertical
        ? localPosition.dy - center.dy
        : localPosition.dx - center.dx;
    final clampedDelta = axisDelta.clamp(-_maxTravel, _maxTravel).toDouble();
    double nextValue = _isVertical
        ? (-clampedDelta / _maxTravel) * 100
        : (clampedDelta / _maxTravel) * 100;

    if (!widget.allowPositive && nextValue > 0) {
      nextValue = 0;
    } else if (!widget.allowNegative && nextValue < 0) {
      nextValue = 0;
    }

    if ((nextValue - _value).abs() >= _epsilon) {
      setState(() => _value = nextValue);
      widget.onChanged(nextValue.round());
    }
  }

  void _reset() {
    if (_value.abs() >= _epsilon) {
      setState(() => _value = 0);
      widget.onChanged(0);
    }
  }

  String _buttonAsset({required bool positiveSide}) {
    final isActive =
        (positiveSide && _value > _epsilon) ||
        (!positiveSide && _value < -_epsilon);
    return isActive
        ? _kClickButtonActiveSvgAsset
        : _kClickButtonInactiveSvgAsset;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        if (!_isDragging) {
          setState(() => _isDragging = true);
        }
        _updateValue(details.localPosition);
      },
      onPanUpdate: (details) {
        if (!_isDragging) return;
        _updateValue(details.localPosition);
      },
      onPanEnd: (_) {
        if (_isDragging) {
          setState(() => _isDragging = false);
        }
        _reset();
      },
      onPanCancel: () {
        if (_isDragging) {
          setState(() => _isDragging = false);
        }
        _reset();
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (_isVertical)
              Positioned(
                top: 0,
                child: SizedBox(
                  width: widget.width,
                  height: widget.width,
                  child: Transform.rotate(
                    angle: -math.pi / 2,
                    child: SvgPicture.asset(
                      key: controlPositiveKey,
                      _buttonAsset(positiveSide: true),
                      width: widget.width,
                      height: widget.width,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            if (_isVertical)
              Positioned(
                bottom: 0,
                child: SizedBox(
                  width: widget.width,
                  height: widget.width,
                  child: Transform.rotate(
                    angle: math.pi / 2,
                    child: SvgPicture.asset(
                      key: controlNegativeKey,
                      _buttonAsset(positiveSide: false),
                      width: widget.width,
                      height: widget.width,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            if (!_isVertical)
              Positioned(
                left: 0,
                top: 0,
                child: SizedBox(
                  width: widget.height,
                  height: widget.height,
                  child: Transform.rotate(
                    angle: -math.pi,
                    child: SvgPicture.asset(
                      key: controlNegativeKey,
                      _buttonAsset(positiveSide: false),
                      width: widget.height,
                      height: widget.height,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            if (!_isVertical)
              Positioned(
                right: 0,
                top: 0,
                child: SizedBox(
                  width: widget.height,
                  height: widget.height,
                  child: SvgPicture.asset(
                    key: controlPositiveKey,
                    _buttonAsset(positiveSide: true),
                    width: widget.height,
                    height: widget.height,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (_isDragging) _buildThumb(_isVertical),
          ],
        ),
      ),
    );
  }

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
        key: controlThumbKey,
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

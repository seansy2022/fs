import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'floating_control_zone.dart';
import 'vertical_floating_control_zone.dart';

const gyroDirectionalThrottleUpArrowKey =
    ValueKey<String>('gyro-hint-up-arrow');
const gyroDirectionalThrottleDownArrowKey =
    ValueKey<String>('gyro-hint-down-arrow');
const gyroDirectionalThrottleDotKey = ValueKey<String>('gyro-hint-dot');
const gyroDirectionalThrottleThumbKey =
    ValueKey<String>('gyro-directional-throttle-thumb');

const _gyroControlActiveSvgAsset =
    'packages/rc_ui/lib/src/assets/assets/点击.svg';
const _gyroControlInactiveSvgAsset =
    'packages/rc_ui/lib/src/assets/assets/点击_wei.svg';
const _gyroControlThumbSvgAsset = 'packages/rc_ui/lib/src/assets/assets/手柄点.svg';

class GyroDirectionalThrottleControl extends StatefulWidget {
  const GyroDirectionalThrottleControl({
    super.key,
    required this.positiveThrottle,
    required this.onChanged,
    this.floating = false,
    this.showArrowHint = false,
    this.floatingWidth = 160,
    this.floatingHeight = 260,
  });

  final bool positiveThrottle;
  final ValueChanged<double> onChanged;
  final bool floating;
  final bool showArrowHint;
  final double floatingWidth;
  final double floatingHeight;

  @override
  State<GyroDirectionalThrottleControl> createState() =>
      _GyroDirectionalThrottleControlState();
}

class _GyroDirectionalThrottleControlState
    extends State<GyroDirectionalThrottleControl> {
  bool _showHint = true;

  @override
  void didUpdateWidget(covariant GyroDirectionalThrottleControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showArrowHint && _showHint) {
      _showHint = false;
    } else if (widget.showArrowHint && !oldWidget.showArrowHint) {
      _showHint = true;
    }
  }

  void _setHintVisible(bool visible) {
    if (_showHint == visible) {
      return;
    }
    setState(() {
      _showHint = visible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = (double value) {
      widget.onChanged(value);
    };

    final child = widget.floating
        ? VerticalFloatingControlZone(
            width: widget.floatingWidth,
            height: widget.floatingHeight,
            allowPositive: widget.positiveThrottle,
            allowNegative: !widget.positiveThrottle,
            onChanged: onChanged,
          )
        : _FixedGyroDirectionalThrottleControl(
            positiveThrottle: widget.positiveThrottle,
            onChanged: onChanged,
          );
    final interactiveChild = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (widget.showArrowHint) {
          _setHintVisible(false);
        }
      },
      onPointerUp: (_) {
        if (widget.showArrowHint) {
          _setHintVisible(true);
        }
      },
      onPointerCancel: (_) {
        if (widget.showArrowHint) {
          _setHintVisible(true);
        }
      },
      child: child,
    );
    if (!widget.showArrowHint) {
      return interactiveChild;
    }
    return _GyroArrowHintOverlay(
      upArrow: widget.positiveThrottle,
      visible: _showHint,
      child: interactiveChild,
    );
  }
}

class _GyroArrowHintOverlay extends StatelessWidget {
  const _GyroArrowHintOverlay({
    required this.upArrow,
    required this.visible,
    required this.child,
  });

  final bool upArrow;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (visible)
          IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: upArrow
                  ? const [
                      // _GyroHintDot(),
                      // SizedBox(height: 2),
                      // Icon(
                      //   Icons.keyboard_arrow_up_rounded,
                      //   key: gyroDirectionalThrottleUpArrowKey,
                      //   size: 24,
                      //   color: Color(0xFFEDF5FF),
                      // ),
                    ]
                  : const [
                      // _GyroHintDot(),
                      // SizedBox(height: 2),
                      // Icon(
                      //   Icons.keyboard_arrow_down_rounded,
                      //   key: gyroDirectionalThrottleDownArrowKey,
                      //   size: 24,
                      //   color: Color(0xFFEDF5FF),
                      // ),
                    ],
            ),
          ),
      ],
    );
  }
}

class _FixedGyroDirectionalThrottleControl extends StatefulWidget {
  const _FixedGyroDirectionalThrottleControl({
    required this.positiveThrottle,
    required this.onChanged,
  });

  final bool positiveThrottle;
  final ValueChanged<double> onChanged;

  @override
  State<_FixedGyroDirectionalThrottleControl> createState() =>
      _FixedGyroDirectionalThrottleControlState();
}

class _FixedGyroDirectionalThrottleControlState
    extends State<_FixedGyroDirectionalThrottleControl> {
  static const _epsilon = 0.0001;
  static const _visibleWidth = 100.0;
  static const _visibleHeight = 120.0;
  static const _visibleThumbRange = _visibleHeight - _thumbSize;
  static const _buttonSize = 100.0;
  static const _thumbSize = 44.0;

  double _value = 0;
  double _thumbTop = 0;
  bool _isDragging = false;

  void _updateValue(Offset localPosition) {
    final clampedDy = localPosition.dy.clamp(0.0, _visibleHeight).toDouble();
    final progress = (clampedDy / _visibleHeight).clamp(0.0, 1.0);
    final clampedThumbTop = progress * _visibleThumbRange;
    final nextValue =
        widget.positiveThrottle ? (1.0 - progress) : (-progress);

    if ((nextValue - _value).abs() < _epsilon &&
        (clampedThumbTop - _thumbTop).abs() < _epsilon) {
      return;
    }
    setState(() {
      _thumbTop = clampedThumbTop;
      _value = nextValue;
      _isDragging = true;
    });
    widget.onChanged(_value);
  }

  void _startDrag(Offset localPosition) {
    if (!_isDragging) {
      setState(() {
        _isDragging = true;
      });
    }
    _updateValue(localPosition);
  }

  void _reset() {
    if (_isDragging || _value.abs() >= _epsilon || _thumbTop != 0) {
      setState(() {
        _isDragging = false;
        _value = 0;
        _thumbTop = 0;
      });
    }
    widget.onChanged(0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _visibleWidth,
      height: _visibleHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) => _startDrag(details.localPosition),
        onPanUpdate: (details) => _updateValue(details.localPosition),
        onPanEnd: (_) => _reset(),
        onPanCancel: _reset,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: widget.positiveThrottle ? 0 : null,
              bottom: widget.positiveThrottle ? null : 0,
              child: SizedBox(
                width: _visibleWidth,
                height: _buttonSize,
                child: Transform.rotate(
                  angle:
                      widget.positiveThrottle ? (-math.pi / 2) : (math.pi / 2),
                  child: SvgPicture.asset(
                    _value.abs() > _epsilon
                        ? _gyroControlActiveSvgAsset
                        : _gyroControlInactiveSvgAsset,
                    width: _visibleWidth,
                    height: _buttonSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (_isDragging)
              Positioned(
                left: (_visibleWidth - _thumbSize) / 2,
                top: _thumbTop,
                child: SizedBox(
                  key: gyroDirectionalThrottleThumbKey,
                  width: _thumbSize,
                  height: _thumbSize,
                  child: SvgPicture.asset(
                    _gyroControlThumbSvgAsset,
                    width: _thumbSize,
                    height: _thumbSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GyroHintDot extends StatelessWidget {
  const _GyroHintDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: gyroDirectionalThrottleDotKey,
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFFEDF5FF),
        shape: BoxShape.circle,
      ),
    );
  }
}

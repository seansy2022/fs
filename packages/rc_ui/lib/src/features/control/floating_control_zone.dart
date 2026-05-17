import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum FloatingControlDirection { vertical, horizontal }

const floatingControlBaseKey = ValueKey<String>('floating-control-base');
const floatingControlThumbKey = ValueKey<String>('floating-control-thumb');
const floatingControlPositiveKey = ValueKey<String>(
  'floating-control-positive',
);
const floatingControlNegativeKey = ValueKey<String>(
  'floating-control-negative',
);

const _kControlWidth = 100.0;
const _kControlHeight = 206.0;
const _kClickButtonActiveSvgAsset =
    'packages/rc_ui/lib/src/assets/assets/点击.svg';
const _kClickButtonInactiveSvgAsset =
    'packages/rc_ui/lib/src/assets/assets/点击_wei.svg';
const _kThumbSvgAsset = 'packages/rc_ui/lib/src/assets/assets/手柄点.svg';

class FloatingControlZone extends StatefulWidget {
  const FloatingControlZone({
    super.key,
    required this.direction,
    required this.onChanged,
    double? width,
    double? height,
    double? controlWidth,
    double? controlHeight,
    this.thumbSize = 44,
    this.allowPositive = true,
    this.allowNegative = true,
  }) : controlWidth =
           controlWidth ??
           (direction == FloatingControlDirection.vertical
               ? _kControlWidth
               : _kControlHeight),
       controlHeight =
           controlHeight ??
           (direction == FloatingControlDirection.vertical
               ? _kControlHeight
               : _kControlWidth),
       width =
           width ??
           (controlWidth ??
               (direction == FloatingControlDirection.vertical
                   ? _kControlWidth
                   : _kControlHeight)),
       height =
           height ??
           (controlHeight ??
               (direction == FloatingControlDirection.vertical
                   ? _kControlHeight
                   : _kControlWidth));

  final FloatingControlDirection direction;
  final ValueChanged<double> onChanged;
  final double width;
  final double height;
  final double controlWidth;
  final double controlHeight;
  final double thumbSize;
  final bool allowPositive;
  final bool allowNegative;

  @override
  State<FloatingControlZone> createState() => _FloatingControlZoneState();
}

class _FloatingControlZoneState extends State<FloatingControlZone> {
  Offset? _origin;
  double _axisOffset = 0;
  bool _visible = false;
  _VerticalGestureIntent? _verticalGestureIntent;

  bool get _isVertical => widget.direction == FloatingControlDirection.vertical;

  bool get _hasDirectionalIntent => _axisOffset.abs() > 0;

  String _buttonAsset({required bool positiveSide}) {
    final isActive =
        _visible &&
        switch ((positiveSide, _isVertical)) {
          (true, true) => _axisOffset < 0,
          (false, true) => _axisOffset > 0,
          (true, false) => _axisOffset > 0,
          (false, false) => _axisOffset < 0,
        };
    return isActive
        ? _kClickButtonActiveSvgAsset
        : _kClickButtonInactiveSvgAsset;
  }

  double get _maxTravel {
    final axisExtent = _isVertical ? widget.controlHeight : widget.controlWidth;
    return (axisExtent - widget.thumbSize) / 2;
  }

  double _clampAxisOrigin({
    required double origin,
    required double halfExtent,
    required double sizeExtent,
  }) {
    if (sizeExtent <= halfExtent * 2) {
      return sizeExtent / 2;
    }
    final min = halfExtent;
    final max = sizeExtent - halfExtent;
    return origin.clamp(min, max).toDouble();
  }

  Offset _clampOrigin(Offset origin) {
    final size = context.size;
    if (size == null) {
      return origin;
    }
    final halfWidth = widget.controlWidth / 2;
    final halfHeight = widget.controlHeight / 2;
    return Offset(
      _clampAxisOrigin(
        origin: origin.dx,
        halfExtent: halfWidth,
        sizeExtent: size.width,
      ),
      _clampAxisOrigin(
        origin: origin.dy,
        halfExtent: halfHeight,
        sizeExtent: size.height,
      ),
    );
  }

  void _handlePanDown(Offset localPosition) {
    final clampedOrigin = _clampOrigin(localPosition);
    setState(() {
      _origin = clampedOrigin;
      _axisOffset = 0;
      _visible = true;
      _verticalGestureIntent = null;
    });
    widget.onChanged(0);
  }

  void _handlePanUpdate(Offset localPosition) {
    final origin = _origin;
    if (origin == null) return;

    final delta = _isVertical
        ? localPosition.dy - origin.dy
        : localPosition.dx - origin.dx;
    var clampedOffset = delta.clamp(-_maxTravel, _maxTravel).toDouble();
    var nextValue = _isVertical
        ? (-clampedOffset / _maxTravel)
        : (clampedOffset / _maxTravel);

    if (_isVertical && widget.allowPositive && widget.allowNegative) {
      final gestureIntent = _verticalGestureIntent;
      if (gestureIntent == null && nextValue != 0) {
        _verticalGestureIntent = nextValue > 0
            ? _VerticalGestureIntent.positive
            : _VerticalGestureIntent.negative;
      }

      if (_verticalGestureIntent == _VerticalGestureIntent.positive &&
          nextValue < 0) {
        clampedOffset = 0;
        nextValue = 0;
      } else if (_verticalGestureIntent == _VerticalGestureIntent.negative &&
          nextValue > 0) {
        clampedOffset = 0;
        nextValue = 0;
      }
    }

    if (!widget.allowPositive && nextValue > 0) {
      clampedOffset = 0;
      nextValue = 0;
    } else if (!widget.allowNegative && nextValue < 0) {
      clampedOffset = 0;
      nextValue = 0;
    }

    if (_axisOffset != clampedOffset || !_visible) {
      setState(() {
        _axisOffset = clampedOffset;
        _visible = true;
      });
    }

    widget.onChanged(nextValue);
  }

  void _reset() {
    final hadState = _visible || _origin != null || _axisOffset != 0;
    if (hadState) {
      setState(() {
        _visible = false;
        _origin = null;
        _axisOffset = 0;
        _verticalGestureIntent = null;
      });
    }
    widget.onChanged(0);
  }

  @override
  Widget build(BuildContext context) {
    final origin = _origin;
    final thumbCenter = origin == null
        ? null
        : _isVertical
        ? Offset(origin.dx, origin.dy + _axisOffset)
        : Offset(origin.dx + _axisOffset, origin.dy);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (details) => _handlePanDown(details.localPosition),
      onPanUpdate: (details) => _handlePanUpdate(details.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (_visible && origin != null) ...[
              _buildControlChrome(origin),
              Positioned(
                left: thumbCenter!.dx - (widget.thumbSize / 2),
                top: thumbCenter.dy - (widget.thumbSize / 2),
                child: IgnorePointer(
                  child: SvgPicture.asset(
                    key: floatingControlThumbKey,
                    _kThumbSvgAsset,
                    width: widget.thumbSize,
                    height: widget.thumbSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlChrome(Offset origin) {
    if (_isVertical) {
      final top = origin.dy - (widget.controlHeight / 2);
      final bottom =
          origin.dy + (widget.controlHeight / 2) - widget.controlWidth;
      final left = origin.dx - (widget.controlWidth / 2);
      final showPositive = _axisOffset < 0;
      final showNegative = _axisOffset > 0;

      return IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              key: floatingControlBaseKey,
              left: left,
              top: top,
              child: SizedBox(
                width: widget.controlWidth,
                height: widget.controlWidth,
                child: Transform.rotate(
                  angle: -1.5707963267948966,
                  child: SvgPicture.asset(
                    key: floatingControlPositiveKey,
                    showPositive
                        ? _kClickButtonActiveSvgAsset
                        : _kClickButtonInactiveSvgAsset,
                    width: widget.controlWidth,
                    height: widget.controlWidth,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              left: left,
              top: bottom,
              child: SizedBox(
                width: widget.controlWidth,
                height: widget.controlWidth,
                child: Transform.rotate(
                  angle: 1.5707963267948966,
                  child: SvgPicture.asset(
                    key: floatingControlNegativeKey,
                    showNegative
                        ? _kClickButtonActiveSvgAsset
                        : _kClickButtonInactiveSvgAsset,
                    width: widget.controlWidth,
                    height: widget.controlWidth,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final left = origin.dx - (widget.controlWidth / 2);
    final right = origin.dx + (widget.controlWidth / 2) - widget.controlHeight;
    final top = origin.dy - (widget.controlHeight / 2);
    final showPositive = _axisOffset > 0;
    final showNegative = _axisOffset < 0;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            key: floatingControlBaseKey,
            left: left,
            top: top,
            child: SizedBox(
              width: widget.controlHeight,
              height: widget.controlHeight,
              child: Transform.rotate(
                angle: -3.141592653589793,
                child: SvgPicture.asset(
                  key: floatingControlNegativeKey,
                  showNegative
                      ? _kClickButtonActiveSvgAsset
                      : _kClickButtonInactiveSvgAsset,
                  width: widget.controlHeight,
                  height: widget.controlHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            left: right,
            top: top,
            child: SizedBox(
              width: widget.controlHeight,
              height: widget.controlHeight,
              child: SvgPicture.asset(
                key: floatingControlPositiveKey,
                showPositive
                    ? _kClickButtonActiveSvgAsset
                    : _kClickButtonInactiveSvgAsset,
                width: widget.controlHeight,
                height: widget.controlHeight,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _VerticalGestureIntent { positive, negative }

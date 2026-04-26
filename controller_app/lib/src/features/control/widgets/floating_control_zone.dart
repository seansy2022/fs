import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum FloatingControlDirection { vertical, horizontal }

const floatingControlBaseKey = ValueKey<String>('floating-control-base');
const floatingControlThumbKey = ValueKey<String>('floating-control-thumb');
const floatingControlPositiveKey = ValueKey<String>('floating-control-positive');
const floatingControlNegativeKey = ValueKey<String>('floating-control-negative');

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
    this.thumbSize = 44,
    this.allowPositive = true,
    this.allowNegative = true,
  }) : width =
           width ??
           (direction == FloatingControlDirection.vertical
               ? _kControlWidth
               : _kControlHeight),
       height =
           height ??
           (direction == FloatingControlDirection.vertical
               ? _kControlHeight
               : _kControlWidth);

  final FloatingControlDirection direction;
  final ValueChanged<double> onChanged;
  final double width;
  final double height;
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

  bool get _isVertical =>
      widget.direction == FloatingControlDirection.vertical;

  bool get _hasDirectionalIntent => _axisOffset.abs() > 0;

  String _buttonAsset({required bool positiveSide}) {
    final isActive = _visible && switch ((positiveSide, _isVertical)) {
      (true, true) => _axisOffset < 0,
      (false, true) => _axisOffset > 0,
      (true, false) => _axisOffset > 0,
      (false, false) => _axisOffset < 0,
    };
    return isActive ? _kClickButtonActiveSvgAsset : _kClickButtonInactiveSvgAsset;
  }

  double get _maxTravel {
    final axisExtent = _isVertical ? widget.height : widget.width;
    return (axisExtent - widget.thumbSize) / 2;
  }

  void _handlePanDown(Offset localPosition) {
    setState(() {
      _origin = localPosition;
      _axisOffset = 0;
      _visible = true;
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
    if (!_hasDirectionalIntent) {
      return const SizedBox.shrink();
    }

    if (_isVertical) {
      final top = origin.dy - (widget.height / 2);
      final bottom = origin.dy + (widget.height / 2) - widget.width;
      final left = origin.dx - (widget.width / 2);
      final showPositive = _axisOffset < 0;

      return IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (showPositive)
              Positioned(
                key: floatingControlBaseKey,
                left: left,
                top: top,
                child: SizedBox(
                  width: widget.width,
                  height: widget.width,
                  child: Transform.rotate(
                    angle: -1.5707963267948966,
                    child: SvgPicture.asset(
                      key: floatingControlPositiveKey,
                      _buttonAsset(positiveSide: true),
                      width: widget.width,
                      height: widget.width,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              )
            else
              Positioned(
                key: floatingControlBaseKey,
                left: left,
                top: bottom,
                child: SizedBox(
                  width: widget.width,
                  height: widget.width,
                  child: Transform.rotate(
                    angle: 1.5707963267948966,
                    child: SvgPicture.asset(
                      key: floatingControlNegativeKey,
                      _buttonAsset(positiveSide: false),
                      width: widget.width,
                      height: widget.width,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final left = origin.dx - (widget.width / 2);
    final right = origin.dx + (widget.width / 2) - widget.height;
    final top = origin.dy - (widget.height / 2);
    final showPositive = _axisOffset > 0;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showPositive)
            Positioned(
              key: floatingControlBaseKey,
              left: right,
              top: top,
              child: SizedBox(
                width: widget.height,
                height: widget.height,
                child: Transform.rotate(
                  angle: -3.141592653589793,
                  child: SvgPicture.asset(
                    key: floatingControlPositiveKey,
                    _buttonAsset(positiveSide: true),
                    width: widget.height,
                    height: widget.height,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            )
          else
            Positioned(
              key: floatingControlBaseKey,
              left: left,
              top: top,
              child: SizedBox(
                width: widget.height,
                height: widget.height,
                child: SvgPicture.asset(
                  key: floatingControlNegativeKey,
                  _buttonAsset(positiveSide: false),
                  width: widget.height,
                  height: widget.height,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

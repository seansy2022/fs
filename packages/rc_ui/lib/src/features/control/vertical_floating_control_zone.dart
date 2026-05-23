import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'floating_control_zone.dart'
    show
        floatingControlBaseKey,
        floatingControlNegativeKey,
        floatingControlPositiveKey,
        floatingControlThumbKey;

const _kVerticalControlWidth = 100.0;
const _kVerticalControlHeight = 206.0;
const _kVerticalClickButtonActiveSvgAsset =
    'packages/rc_ui/lib/src/assets/assets/点击.svg';
const _kVerticalClickButtonInactiveSvgAsset =
    'packages/rc_ui/lib/src/assets/assets/点击_wei.svg';
const _kVerticalThumbSvgAsset =
    'packages/rc_ui/lib/src/assets/assets/手柄点.svg';

class VerticalFloatingControlZone extends StatefulWidget {
  const VerticalFloatingControlZone({
    super.key,
    required this.onChanged,
    double? width,
    double? height,
    this.controlWidth = _kVerticalControlWidth,
    this.controlHeight = _kVerticalControlHeight,
    this.thumbSize = 44,
    this.allowPositive = true,
    this.allowNegative = true,
  }) : width = width ?? _kVerticalControlWidth,
       height = height ?? _kVerticalControlHeight;

  final ValueChanged<double> onChanged;
  final double width;
  final double height;
  final double controlWidth;
  final double controlHeight;
  final double thumbSize;
  final bool allowPositive;
  final bool allowNegative;

  @override
  State<VerticalFloatingControlZone> createState() =>
      _VerticalFloatingControlZoneState();
}

class _VerticalFloatingControlZoneState
    extends State<VerticalFloatingControlZone> {
  Offset? _origin;
  double _axisOffset = 0;
  bool _visible = false;

  double get _maxTravel => (widget.controlHeight - widget.thumbSize) / 2;

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
    });
    widget.onChanged(0);
  }

  void _handlePanUpdate(Offset localPosition) {
    final origin = _origin;
    if (origin == null) {
      return;
    }

    final delta = localPosition.dy - origin.dy;
    var clampedOffset = delta.clamp(-_maxTravel, _maxTravel).toDouble();
    var nextValue = -clampedOffset / _maxTravel;

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
        _origin = null;
        _axisOffset = 0;
        _visible = false;
      });
    }
    widget.onChanged(0);
  }

  @override
  Widget build(BuildContext context) {
    final origin = _origin;
    final thumbCenter = origin == null
        ? null
        : Offset(origin.dx, origin.dy + _axisOffset);

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
                    _kVerticalThumbSvgAsset,
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
    final top = origin.dy - (widget.controlHeight / 2);
    final bottom = origin.dy + (widget.controlHeight / 2) - widget.controlWidth;
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
            child: const SizedBox.shrink(),
          ),
          Positioned(
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
                      ? _kVerticalClickButtonActiveSvgAsset
                      : _kVerticalClickButtonInactiveSvgAsset,
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
                      ? _kVerticalClickButtonActiveSvgAsset
                      : _kVerticalClickButtonInactiveSvgAsset,
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
}

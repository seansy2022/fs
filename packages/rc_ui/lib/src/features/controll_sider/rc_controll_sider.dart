import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/src/core/app_assets.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';
import 'package:rc_ui/src/elements/button/rc_icon_button.dart';

enum RCControllSiderDirection { horizontal, vertical }

class RCControllSider extends StatefulWidget {
  const RCControllSider({
    super.key,
    this.direction = RCControllSiderDirection.horizontal,
    this.initialValue = 0,
    this.step = 0.1,
    this.trackMain = 140,
    this.enabled = true,
    this.showButtons = true,
    this.lockSignUntilRelease = false,
    this.onChanged,
  });

  final RCControllSiderDirection direction;

  /// Current value in range [-1, 1], where 0 is centered.
  final double initialValue;

  /// Button increment/decrement step.
  final double step;
  final double trackMain;

  final bool enabled;
  final bool showButtons;
  final bool lockSignUntilRelease;

  final ValueChanged<double>? onChanged;

  @override
  State<RCControllSider> createState() => _RCControllSiderState();
}

class _RCControllSiderState extends State<RCControllSider> {
  static const _buttonSize = 24.0;
  static const _buttonGap = 8.0;
  static const _thumbSize = 20.0;
  static const _trackCross = 10.0;

  late double _value;
  int? _dragSignLock;

  bool get _isHorizontal =>
      widget.direction == RCControllSiderDirection.horizontal;
  double get _trackMain => widget.trackMain;

  @override
  void initState() {
    super.initState();
    _value = _clamp(widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant RCControllSider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _setValue(widget.initialValue, emit: false);
    }
  }

  void _setValue(double next, {bool emit = true}) {
    final clamped = _clamp(next);
    if ((_value - clamped).abs() < 0.0001) return;
    setState(() => _value = clamped);
    if (emit) {
      widget.onChanged?.call(_value);
    }
  }

  double _clamp(double input) => input.clamp(-1.0, 1.0);

  void _minus() => _stepToward(_value - widget.step);
  void _plus() => _stepToward(_value + widget.step);

  void _stepToward(double next) {
    if (!widget.enabled) {
      return;
    }
    var candidate = next;
    if (widget.lockSignUntilRelease) {
      final currentSign = _signOf(_value);
      final nextSign = _signOf(candidate);
      if (currentSign != 0 && nextSign != 0 && currentSign != nextSign) {
        candidate = 0;
      }
    }
    _setValue(candidate);
  }

  int _signOf(double value) {
    if (value > 0.0001) return 1;
    if (value < -0.0001) return -1;
    return 0;
  }

  void _startDrag(Offset localPos, double trackMain) {
    if (!widget.enabled) {
      return;
    }
    _dragSignLock = widget.lockSignUntilRelease ? _signOf(_value) : null;
    _onDrag(localPos, trackMain);
  }

  void _onDrag(Offset localPos, double trackMain) {
    if (!widget.enabled) {
      return;
    }
    final drag = _isHorizontal ? localPos.dx : localPos.dy;
    final usable = trackMain - _thumbSize;
    final raw = ((drag - (_thumbSize / 2)) / usable).clamp(0.0, 1.0);
    // Map [0,1] -> [-1,1], vertical keeps top as +1 and bottom as -1.
    var next = _isHorizontal ? (raw * 2 - 1) : (1 - raw) * 2 - 1;
    if (widget.lockSignUntilRelease) {
      final signLock = _dragSignLock ?? 0;
      if (signLock == 0) {
        final nextSign = _signOf(next);
        if (nextSign != 0) {
          _dragSignLock = nextSign;
        }
      } else if (signLock > 0 && next < 0 || signLock < 0 && next > 0) {
        next = 0;
      }
    }
    _setValue(next);
  }

  double _thumbOffset(double trackMain) {
    final t = (_value + 1) / 2; // [-1, 1] -> [0, 1]
    if (_isHorizontal) {
      return t * (trackMain - _thumbSize);
    }
    return (1 - t) * (trackMain - _thumbSize);
  }

  @override
  Widget build(BuildContext context) {
    final gap = _buttonGap;
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackMain = _resolveTrackMain(constraints);
        if (_isHorizontal) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButtonSlot(child: _buildButton(plus: false, onTap: _minus)),
              SizedBox(width: gap),
              _buildTrack(trackMain),
              SizedBox(width: gap),
              _buildButtonSlot(child: _buildButton(plus: true, onTap: _plus)),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButtonSlot(child: _buildButton(plus: true, onTap: _plus)),
            SizedBox(height: gap),
            _buildTrack(trackMain),
            SizedBox(height: gap),
            _buildButtonSlot(child: _buildButton(plus: false, onTap: _minus)),
          ],
        );
      },
    );
  }

  double _resolveTrackMain(BoxConstraints constraints) {
    final available = _isHorizontal ? constraints.maxWidth : constraints.maxHeight;
    if (!available.isFinite) {
      return _trackMain;
    }
    final reserved = (_buttonSize * 2) + (_buttonGap * 2);
    return (available - reserved).clamp(_thumbSize, _trackMain).toDouble();
  }

  Widget _buildButtonSlot({required Widget child}) {
    return Visibility(
      visible: widget.showButtons,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: child,
    );
  }

  Widget _buildButton({required bool plus, required VoidCallback onTap}) {
    return RCIconButton(
      plus: plus,
      size: _buttonSize,
      iconSize: 10,
      onTap: onTap,
      enableRepeat: true,
    );
  }

  Widget _buildTrack(double trackMain) {
    final thumbCenter = _thumbOffset(trackMain) + (_thumbSize / 2);
    final center = trackMain / 2;
    final fillLength = (thumbCenter - center).abs();

    final track = Container(
      width: _isHorizontal ? trackMain : _trackCross,
      height: _isHorizontal ? _trackCross : trackMain,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(27, 45, 77, 0.4),
        border: Border.all(
          color: const Color.fromRGBO(125, 162, 206, 1),
          width: 0.5,
        ),
        borderRadius: BorderRadius.zero,
      ),
    );

    final thumb = SvgPicture.asset(
      AppAssets.controlSliderThumb,
      width: _thumbSize,
      height: _thumbSize,
      fit: BoxFit.contain,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: widget.enabled
          ? (d) => _startDrag(d.localPosition, trackMain)
          : null,
      onPanUpdate: widget.enabled
          ? (d) => _onDrag(d.localPosition, trackMain)
          : null,
      onPanEnd: widget.enabled ? (_) => _dragSignLock = null : null,
      onPanCancel: widget.enabled ? () => _dragSignLock = null : null,
      child: SizedBox(
        width: _isHorizontal ? trackMain : _thumbSize,
        height: _isHorizontal ? _thumbSize : trackMain,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: _isHorizontal ? 0 : (_thumbSize - _trackCross) / 2,
              top: _isHorizontal ? (_thumbSize - _trackCross) / 2 : 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  track,
                  if (fillLength > 0)
                    _buildProgressFill(
                      thumbCenter: thumbCenter,
                      center: center,
                      fillLength: fillLength,
                    ),
                  _buildZeroTick(),
                ],
              ),
            ),
            Positioned(
              left: _isHorizontal ? _thumbOffset(trackMain) : 0,
              top: _isHorizontal ? 0 : _thumbOffset(trackMain),
              child: thumb,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressFill({
    required double thumbCenter,
    required double center,
    required double fillLength,
  }) {
    if (_isHorizontal) {
      final positive = _value >= 0;
      return Positioned(
        left: positive ? center : thumbCenter,
        top: 0,
        width: fillLength,
        height: _trackCross,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: positive
                ? AppGradients.primary
                : AppGradients.primaryReverse,
          ),
        ),
      );
    }

    final positive = _value >= 0;
    return Positioned(
      left: 0,
      top: positive ? thumbCenter : center,
      width: _trackCross,
      height: fillLength,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: positive
              ? AppGradients.primaryVertical
              : AppGradients.primaryVerticalReverse,
        ),
      ),
    );
  }

  Widget _buildZeroTick() {
    const tickMainColor = Color(0xFF7DA2CE);
    const tickShadowColor = Color(0xFF465D7A);
    const tickStroke = 0.5;
    const tickLength = 8.0;

    if (_isHorizontal) {
      return Positioned(
        left: (_trackMain - (tickStroke * 2)) / 2,
        top: (_trackCross - tickLength) / 2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: tickStroke,
              height: tickLength,
              color: tickMainColor,
            ),
            Container(
              width: tickStroke,
              height: tickLength,
              color: tickShadowColor,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

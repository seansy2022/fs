import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class RCButton extends StatefulWidget {
  const RCButton({
    super.key,
    required this.onTap,
    this.iconWidget,
    this.textWidget,
    this.padding = const EdgeInsets.fromLTRB(12, 6, 12, 6),
    this.gap = 4,
    this.direction = Axis.horizontal,
    this.isRounded = false,
    this.borderRadius,
    this.active = false,
    this.enableRepeat = true,
    this.width,
    this.height,
  });

  final VoidCallback? onTap;
  final Widget? iconWidget;
  final Widget? textWidget;
  final EdgeInsetsGeometry padding;
  final double gap;
  final Axis direction;
  final bool isRounded;
  final double? borderRadius;
  final bool active;
  final bool enableRepeat;
  final double? width;
  final double? height;

  @override
  State<RCButton> createState() => _RCButtonState();
}

class _RCButtonState extends State<RCButton> {
  static const _repeatInterval = Duration(milliseconds: 80);
  Timer? _repeatTimer;
  bool _isPressed = false;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    super.dispose();
  }

  void _trigger() => widget.onTap?.call();

  void _startRepeat(LongPressStartDetails _) {
    _setPressed(true);
    if (!widget.enableRepeat || widget.onTap == null) return;
    _trigger();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(_repeatInterval, (_) => _trigger());
  }

  void _stopRepeat([Object? _]) {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _setPressed(false);
  }

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    if (!mounted) {
      _isPressed = value;
      return;
    }
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadiusVal =
        widget.borderRadius ??
        (widget.isRounded ? 999 : AppDimens.squareButtonRadius);
    final borderRadius = BorderRadius.circular(borderRadiusVal);

    Widget? content;
    final hasIcon = widget.iconWidget != null;
    final hasText = widget.textWidget != null;

    if (hasIcon && hasText) {
      content = Flex(
        direction: widget.direction,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.iconWidget!,
          widget.direction == Axis.horizontal
              ? SizedBox(width: widget.gap)
              : SizedBox(height: widget.gap),
          widget.textWidget!,
        ],
      );
    } else if (hasIcon) {
      content = widget.iconWidget;
    } else if (hasText) {
      content = widget.textWidget;
    }

    final isHighlighted = widget.active || _isPressed;

    return Listener(
      onPointerDown: (_) {
        if (widget.onTap != null) {
          _setPressed(true);
        }
      },
      onPointerUp: (_) => _stopRepeat(),
      onPointerCancel: (_) => _stopRepeat(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _trigger,
        onLongPressStart: _startRepeat,
        onLongPressEnd: _stopRepeat,
        onLongPressCancel: _stopRepeat,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: isHighlighted ? AppGradients.v21 : null,
            borderRadius: borderRadius,
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFF00C6FF)
                  : AppColors.primary,
              width: 0.5,
            ),
          ),
          foregroundDecoration: MetricBorderDecoration(
            hasInnerShadow: true,
            innerShadowColor: const Color(0xA30072FF),
            blurRadius: 4.0,
            radius: borderRadiusVal,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}

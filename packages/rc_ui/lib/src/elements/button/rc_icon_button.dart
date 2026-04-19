import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

enum RCIconButtonType { normal, textButton }

class RCIconButton extends StatefulWidget {
  const RCIconButton({
    super.key,
    this.plus,
    required this.onTap,
    this.text,
    this.icon,
    this.size = AppDimens.squareButton,
    this.iconSize = AppDimens.iconM,
    this.active = false,
    this.enableRepeat = true,
    this.isSquare = true,
    this.width,
    this.padding,
    this.fontSize, // 新增：可选字号
    this.type = RCIconButtonType.normal,
  });

  /// Use hand-drawn plus/minus symbol if provided.
  final bool? plus;
  final VoidCallback? onTap;
  final String? text;
  final IconData? icon;
  final double size;
  final double iconSize;
  final bool active;
  final bool enableRepeat;
  final bool isSquare;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final RCIconButtonType type;

  @override
  State<RCIconButton> createState() => _RCIconButtonState();
}

class _RCIconButtonState extends State<RCIconButton> {
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

  void _onTapDown(TapDownDetails _) => _setPressed(true);
  void _onTapUp(TapUpDetails _) => _setPressed(false);
  void _onTapCancel() => _setPressed(false);

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
    final k = widget.size / 48;
    final borderRadiusVal = widget.isSquare
        ? (widget.size == AppDimens.squareButton
              ? AppDimens.squareButtonRadius
              : widget.size * 0.1)
        : AppDimens.radiusS;
    final borderRadius = BorderRadius.circular(borderRadiusVal);

    Widget content;
    final symbolColor = _symbolColor();

    if (widget.plus != null) {
      content = _Symbol(
        plus: widget.plus!,
        size: widget.iconSize,
        color: symbolColor,
      );
    } else if (widget.icon != null) {
      content = Icon(widget.icon, size: widget.iconSize, color: symbolColor);
    } else {
      content = const SizedBox.shrink();
    }

    if (widget.text != null) {
      if (widget.isSquare) {
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            content,
            const SizedBox(height: 2),
            Text(
              widget.text!,
              style: TextStyle(color: symbolColor, fontSize: AppFonts.s10 * k),
            ),
          ],
        );
      } else {
        content = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            content,
            if (widget.icon != null || widget.plus != null)
              const SizedBox(width: 8),
            Text(
              widget.text!,
              style: TextStyle(
                color: symbolColor,
                fontSize: widget.fontSize ?? AppFonts.s14,
              ),
            ),
          ],
        );
      }
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
          width: widget.width ?? (widget.isSquare ? widget.size : null),
          height: widget.size,
          padding:
              widget.padding ??
              (widget.isSquare
                  ? null
                  : const EdgeInsets.symmetric(horizontal: 16)),
          decoration: BoxDecoration(
            // color: isHighlighted
            //     ? const Color(0x661B2D4D)
            //     : AppColors.surfaceHigh,
            gradient: isHighlighted ? AppGradients.v21 : null,
            boxShadow: [
              // if (isHighlighted)
              //   BoxShadow(
              //     color: const Color(0xFF00C6FF).withValues(alpha: 0.2),
              //     blurRadius: 4,
              //     spreadRadius: 1,
              //   )
              // else
              //   BoxShadow(
              //     color: Colors.black.withValues(alpha: 0.2),
              //     blurRadius: 4,
              //     offset: const Offset(0, 2),
              //   ),
            ],
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
            blurRadius: 4.0, // 显式匹配 CSS 4px 模糊
            radius: borderRadiusVal,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }

  Color _symbolColor() {
    if (widget.active) return AppColors.onPrimary;
    if (widget.type == RCIconButtonType.textButton) {
      return const Color(0xFF7DA2CE);
    }
    return AppColors.text;
  }
}

class _Symbol extends StatelessWidget {
  const _Symbol({required this.plus, required this.size, required this.color});

  final bool plus;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final weight = size / 8;
    final bar = Container(
      width: size,
      height: weight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(weight / 2),
      ),
    );

    if (!plus) return bar;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          bar,
          Container(
            width: weight,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(weight / 2),
            ),
          ),
        ],
      ),
    );
  }
}

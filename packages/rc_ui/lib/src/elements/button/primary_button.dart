
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

enum PrimaryButtonType { primary, iconBtn, normal, outline }

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    this.onTap,
    this.enabled = true,
    this.type = PrimaryButtonType.primary,
    this.icon,
    this.width,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  });

  final VoidCallback? onTap;
  final String text;
  final bool enabled;
  final PrimaryButtonType type;
  final Widget? icon;
  final double? width;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final skin = !_enabled
        ? (
            fill: const Color(0xFF6D7787),
            border: const Color(0xFF6D7787),
            text: const Color(0xFF2F3744),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7D8796), Color(0xFF616B7A)],
            ),
          )
        : switch (widget.type) {
            PrimaryButtonType.primary => (
              fill: AppColors.primary,
              border: Colors.transparent,
              text: AppColors.bg,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryBright, AppColors.primary],
              ),
            ),
            PrimaryButtonType.iconBtn => (
              fill: const Color(0xFF0072FF),
              border: AppColors.primaryBright,
              text: AppColors.onPrimary,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0072FF), Color(0xFF00C8FF)],
              ),
            ),
            PrimaryButtonType.normal => (
              fill: AppColors.surfaceHighest,
              border: AppColors.line,
              text: AppColors.text,
              gradient: null,
            ),
            PrimaryButtonType.outline => (
              fill: Colors.transparent,
              border: AppColors.primary,
              text: AppColors.primary,
              gradient: null,
            ),
          };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _enabled ? widget.onTap : null,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 90),
        opacity: _enabled ? (_pressed ? 0.82 : 1) : 0.62,
        child: Container(
          width: widget.width ?? double.infinity,
          margin: widget.margin,
          constraints: const BoxConstraints(minHeight: 40),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: skin.fill,
            gradient: skin.gradient,
            borderRadius: BorderRadius.circular(
              widget.type == PrimaryButtonType.iconBtn ? 8 : 4,
            ),
            border: Border.all(color: skin.border),
          ),
          child: _content(skin.text),
        ),
      ),
    );
  }

  Widget _content(Color textColor) {
    final style = TextStyle(
      color: textColor,
      fontSize: AppFonts.s16,
      fontWeight: AppFonts.w700,
    );
    if (widget.type != PrimaryButtonType.iconBtn || widget.icon == null) {
      return Center(child: Text(widget.text, style: style));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTheme(
          data: IconThemeData(color: textColor, size: 16),
          child: widget.icon!,
        ),
        if (widget.text.isNotEmpty) const SizedBox(width: 6),
        if (widget.text.isNotEmpty) Text(widget.text, style: style),
      ],
    );
  }
}

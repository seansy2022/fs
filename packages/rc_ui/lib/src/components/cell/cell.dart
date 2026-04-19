import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class Cell extends StatefulWidget {
  const Cell({
    super.key,
    required this.title,
    required this.widget,
    this.onTap,
    this.height = 120,
    this.showBorder = true,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
    this.titleFontSize = AppFonts.s14,
    this.enableHighlight = false,
    this.highlightGradient,
    this.highlightBaseColor,
  });

  final String title;
  final Widget widget;
  final VoidCallback? onTap;
  final double height;
  final bool showBorder;
  final EdgeInsetsGeometry padding;
  final double titleFontSize;
  final bool enableHighlight;
  final Gradient? highlightGradient;
  final Color? highlightBaseColor;

  @override
  State<Cell> createState() => _CellState();
}

class _CellState extends State<Cell> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isPressedHighlight = _isPressed && widget.enableHighlight;
    return Listener(
      onPointerDown: (_) {
        if (widget.onTap != null && widget.enableHighlight) {
          setState(() => _isPressed = true);
        }
      },
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          padding: widget.padding,
          decoration: AppDecorations.metricBase.copyWith(
            color: isPressedHighlight
                ? (widget.highlightBaseColor ?? AppDecorations.metricBase.color)
                : AppDecorations.metricBase.color,
            gradient: isPressedHighlight
                ? (widget.highlightGradient ?? AppGradients.v20)
                : null,
          ), // 根据开关显示按压渐变
          foregroundDecoration: widget.showBorder
              ? const MetricBorderDecoration(
                  solidColor: AppColors.primary,
                  hasInnerShadow: true,
                )
              : null, // 使用公共实线边框 + 内阴影样式
          child: Row(
            children: [
              if (widget.title.isNotEmpty)
                Expanded(child: Text(widget.title, style: _titleStyle())),
              if (widget.title.isNotEmpty) const SizedBox(width: 8),
              widget.widget,
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _titleStyle() {
    return TextStyle(
      color: AppColors.text,
      fontSize: widget.titleFontSize,
      fontWeight: AppFonts.w400,
      height: 1,
    );
  }
}

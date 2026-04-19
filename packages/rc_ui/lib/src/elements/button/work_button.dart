import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class WorkButton extends StatefulWidget {
  const WorkButton({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.active = false,
  });

  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final bool active;

  @override
  State<WorkButton> createState() => _WorkButtonState();
}

class _WorkButtonState extends State<WorkButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AspectRatio(
          aspectRatio: 212 / 232,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
              gradient: (widget.active || _isPressed)
                  ? AppGradients.v20
                  : AppGradients.surfaceFade,
            ),
            foregroundDecoration: const _WorkBorderDecoration(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: AppDimens.squareButton,
                  height: AppDimens.squareButton,
                  child: Center(child: widget.icon),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: AppFonts.s12,
                    // fontWeight: AppFonts.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkBorderDecoration extends Decoration {
  const _WorkBorderDecoration();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _WorkBorderPainter();
}

class _WorkBorderPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    if (cfg.size == null) return;
    final rect = offset & cfg.size!;
    final border = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      const Radius.circular(AppDimens.radiusL),
    );

    // --- 绘制内阴影 (box-shadow: inset 0px 0px 4px rgba(0, 114, 255, 0.64)) ---
    canvas.save();
    canvas.clipRRect(border);
    final innerShadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          4.0 // 模拟内阴影宽度
      ..color =
          const Color(0xA30072FF) // rgba(0, 114, 255, 0.64)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0); // 模糊半径 4
    canvas.drawRRect(border.inflate(2.0), innerShadowPaint);
    canvas.restore();

    // --- 绘制边框 ---
    final gradient = AppGradients.metricBorder;
    canvas.drawRRect(
      border,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..shader = gradient.createShader(rect),
    );
  }
}

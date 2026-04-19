import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/src/core/app_assets.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

enum FourCLayoutMode { frontSame, frontOpposite, rearSame, rearOpposite }

class FourCLayoutOption extends StatefulWidget {
  const FourCLayoutOption({
    super.key,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final FourCLayoutMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<FourCLayoutOption> createState() => _FourCLayoutOptionState();
}

class _FourCLayoutOptionState extends State<FourCLayoutOption> {
  bool _isPressed = false;

  String get _asset => switch (widget.mode) {
    FourCLayoutMode.frontSame =>
      widget.selected
          ? AppAssets.mixingFrontSelect
          : AppAssets.mixingFrontUnselect,
    FourCLayoutMode.frontOpposite =>
      widget.selected
          ? AppAssets.mixingOppositeSelect
          : AppAssets.mixingOppositeUnselect,
    FourCLayoutMode.rearSame =>
      widget.selected
          ? AppAssets.mixingSameSelect
          : AppAssets.mixingSameUnselect,
    FourCLayoutMode.rearOpposite =>
      widget.selected
          ? AppAssets.mixingBackSelect
          : AppAssets.mixingBackUnselect,
  };

  String get _label => switch (widget.mode) {
    FourCLayoutMode.frontSame => '前面',
    FourCLayoutMode.frontOpposite => '前后反向',
    FourCLayoutMode.rearSame => '前后同向',
    FourCLayoutMode.rearOpposite => '后面',
  };

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
            gradient: widget.selected
                ? AppGradients.v20
                : AppGradients.surfaceFade,
          ),
          foregroundDecoration: const _FourCBorderDecoration(),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 50),
            opacity: _isPressed ? 0.9 : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 90,
                    child: SvgPicture.asset(_asset, fit: BoxFit.contain),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 14,
                    fontWeight: AppFonts.w400,
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

class _FourCBorderDecoration extends Decoration {
  const _FourCBorderDecoration();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _FourCBorderPainter();
}

class _FourCBorderPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    if (cfg.size == null) return;
    final rect = offset & cfg.size!;
    final border = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      const Radius.circular(AppDimens.radiusL),
    );

    // 绘制内阴影
    canvas.save();
    canvas.clipRRect(border);
    final innerShadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = const Color(0xA30072FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(border.inflate(2.0), innerShadowPaint);
    canvas.restore();

    // 绘制边框
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

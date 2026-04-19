import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_gradients.dart';

class AppDecorations {
  static BoxDecoration panel = BoxDecoration(
    color: AppColors.surfaceHigh,
    border: Border.all(color: const Color(0xCC0072FF), width: 0.5),
    borderRadius: BorderRadius.circular(AppDimens.radiusL),
    boxShadow: const [
      BoxShadow(color: Color(0x4D000000), blurRadius: 20, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x660072FF), blurRadius: 12),
    ],
  );

  static BoxDecoration metricBase = BoxDecoration(
    color: AppColors.bg,
    borderRadius: BorderRadius.circular(8),
  );
}

class MetricBorderDecoration extends Decoration {
  const MetricBorderDecoration({
    this.solidColor,
    this.hasInnerShadow = false,
    this.innerShadowColor,
    this.blurRadius,
    this.radius = 8,
    this.borderRadius,
  });

  final Color? solidColor;
  final bool hasInnerShadow;
  final Color? innerShadowColor;
  final double? blurRadius;
  final double radius;
  final BorderRadius? borderRadius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return MetricBorderPainter(
      solidColor: solidColor,
      hasInnerShadow: hasInnerShadow,
      innerShadowColor: innerShadowColor,
      blurRadius: blurRadius,
      radius: radius,
      borderRadius: borderRadius,
    );
  }
}

class MetricBorderPainter extends BoxPainter {
  MetricBorderPainter({
    this.solidColor,
    this.hasInnerShadow = false,
    this.innerShadowColor,
    this.blurRadius,
    this.radius = 8,
    this.borderRadius,
  });

  final Color? solidColor;
  final bool hasInnerShadow;
  final Color? innerShadowColor;
  final double? blurRadius;
  final double radius;
  final BorderRadius? borderRadius;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size;
    if (size == null) return;
    final rect = offset & size;

    // 使用传入的 BorderRadius，如果没有则使用统一的 radius
    final rr = borderRadius ?? BorderRadius.circular(radius);
    final r = rr.toRRect(rect.deflate(0.5));

    if (hasInnerShadow) {
      canvas.save();
      canvas.clipRRect(r);
      final shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..color = innerShadowColor ?? const Color(0x3D0072FF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius ?? 8.0);
      canvas.drawRRect(r.inflate(5.0), shadowPaint);
      canvas.restore();
    }

    // --- 绘制边框 ---
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    if (solidColor != null) {
      paint.color = solidColor!;
    } else {
      paint.shader = AppGradients.metricBorder.createShader(rect);
    }

    canvas.drawRRect(r, paint);
  }
}

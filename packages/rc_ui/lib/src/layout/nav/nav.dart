import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/src/core/app_assets.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class TopAppBar extends StatelessWidget {
  const TopAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.onRefresh,
    this.right,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 52 + topInset,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _NavBarPainter())),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, topInset, 0, 0),
            child: SizedBox(
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: onBack != null
                            ? Align(
                                alignment: Alignment(
                                  -1.0,
                                  -0.8,
                                ), // 左对齐，向上偏移约8px
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: _NavBackButton(onTap: onBack!),
                                ),
                              )
                            : null,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 100,
                        child: Align(
                          alignment: Alignment(1.0, -0.8), // 右对齐，向上偏移约8px
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child:
                                right ??
                                (onRefresh != null
                                    ? _NavRefreshButton(onTap: onRefresh!)
                                    : null),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: AppFonts.w700,
                        letterSpacing: 0.8,
                        fontSize: AppFonts.s16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBackButton extends StatelessWidget {
  const _NavBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: SvgPicture.asset(AppAssets.back, width: 22, height: 22),
          ),
        ),
      ),
    );
  }
}

class _NavRefreshButton extends StatelessWidget {
  const _NavRefreshButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: SvgPicture.asset(
              AppAssets.refresh,
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                AppColors.text,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarPainter extends CustomPainter {
  static const double _svgW = 750;
  static const double _svgH = 180;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildMainPath(size);
    final sx = size.width / _svgW;
    final sy = size.height / _svgH;
    final scale = sx < sy ? sx : sy;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF001024),
    );

    final borderWidth = 2 * sy;

    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(
      path.shift(Offset(0, -12 * sy)),
      //阴影
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth * 4
        ..color = const Color(0xA30072FF)
        ..blendMode = BlendMode.srcATop
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30 * scale),
    );
    canvas.restore();

    final line1 = _buildLinePath1(size);
    final line2 = _buildLinePath2(size);
    final g1 = const LinearGradient(
      colors: [
        Color(0xFF7DA2CE),
        Color(0xFF00C6FF),
        Color(0xFF92FE9D),
        Color(0xFF00C8FF),
        Color(0xFF7DA2CE),
      ],
      stops: [0.0, 0.3334, 0.5092, 0.678, 1.0],
    );
    final g2 = const LinearGradient(
      colors: [
        Color(0xFF7DA2CE),
        Color(0xFF00C6FF),
        Color(0xFF92FE9D),
        Color(0xFF00C8FF),
        Color(0xFF7DA2CE),
      ],
      stops: [0.0, 0.3334, 0.5092, 0.678, 1.0],
    );
    canvas.drawPath(
      line1,
      Paint()
        ..shader = g1.createShader(Rect.fromLTWH(0, 167 * sy, size.width, 1)),
    );
    canvas.drawPath(
      line2,
      Paint()
        ..shader = g2.createShader(Rect.fromLTWH(0, 163.5 * sy, size.width, 1)),
    );

    final decoPaint = Paint()..color = const Color(0xFF233854);
    _drawBottomDecoLeft(canvas, size, decoPaint);
    _drawBottomDecoRight(canvas, size, decoPaint);
  }

  Path _buildMainPath(Size size) {
    final sx = size.width / _svgW;
    final sy = size.height / _svgH;
    final path = Path()
      ..moveTo(0 * sx, 156 * sy)
      ..lineTo(157.5 * sx, 156 * sy)
      ..cubicTo(
        159.1 * sx,
        156 * sy,
        160.54 * sx,
        156.5 * sy,
        161.64 * sx,
        157.6 * sy,
      )
      ..lineTo(181.95 * sx, 177.7 * sy)
      ..cubicTo(
        183.45 * sx,
        179.2 * sy,
        185.449 * sx,
        180 * sy,
        187.55 * sx,
        180 * sy,
      )
      ..lineTo(562.85 * sx, 180 * sy)
      ..cubicTo(
        564.951 * sx,
        180 * sy,
        566.95 * sx,
        179.2 * sy,
        568.45 * sx,
        177.7 * sy,
      )
      ..lineTo(588.56 * sx, 157.7 * sy)
      ..cubicTo(
        589.66 * sx,
        156.6 * sy,
        591.4 * sx,
        156 * sy,
        593 * sx,
        156 * sy,
      )
      ..lineTo(750 * sx, 156 * sy)
      ..lineTo(750 * sx, 0)
      ..lineTo(0, 0)
      ..close();
    return path;
  }

  Path _buildLinePath1(Size size) {
    final sx = size.width / _svgW;
    final sy = size.height / _svgH;
    return Path()
      ..moveTo(0, 155.992 * sy)
      ..lineTo(157.44 * sx, 155.992 * sy)
      ..cubicTo(
        158.113 * sx,
        155.992 * sy,
        158.75 * sx,
        156.113 * sy,
        159.353 * sx,
        156.356 * sy,
      )
      ..cubicTo(
        159.954 * sx,
        156.597 * sy,
        160.48 * sx,
        156.943 * sy,
        160.933 * sx,
        157.394 * sy,
      )
      ..lineTo(181.243 * sx, 177.417 * sy)
      ..cubicTo(
        182.087 * sx,
        178.256 * sy,
        183.054 * sx,
        178.897 * sy,
        184.147 * sx,
        179.341 * sy,
      )
      ..cubicTo(
        185.228 * sx,
        179.78 * sy,
        186.363 * sx,
        180 * sy,
        187.55 * sx,
        180 * sy,
      )
      ..lineTo(562.85 * sx, 180 * sy)
      ..cubicTo(
        564.037 * sx,
        180 * sy,
        565.172 * sx,
        179.78 * sy,
        566.253 * sx,
        179.341 * sy,
      )
      ..cubicTo(
        567.347 * sx,
        178.896 * sy,
        568.314 * sx,
        178.256 * sy,
        569.155 * sx,
        177.419 * sy,
      )
      ..lineTo(589.267 * sx, 157.494 * sy)
      ..cubicTo(
        589.741 * sx,
        157.022 * sy,
        590.277 * sx,
        156.655 * sy,
        590.874 * sx,
        156.394 * sy,
      )
      ..cubicTo(
        591.487 * sx,
        156.126 * sy,
        592.115 * sx,
        155.992 * sy,
        592.76 * sx,
        155.992 * sy,
      )
      ..lineTo(750 * sx, 155.992 * sy)
      ..lineTo(750 * sx, 154 * sy)
      ..lineTo(592.76 * sx, 154 * sy)
      ..cubicTo(
        591.836 * sx,
        154 * sy,
        590.94 * sx,
        154.19 * sy,
        590.071 * sx,
        154.57 * sy,
      )
      ..cubicTo(
        589.244 * sx,
        154.931 * sy,
        588.506 * sx,
        155.435 * sy,
        587.855 * sx,
        156.083 * sy,
      )
      ..lineTo(567.743 * sx, 176.008 * sy)
      ..cubicTo(
        567.092 * sx,
        176.656 * sy,
        566.344 * sx,
        177.152 * sy,
        565.497 * sx,
        177.496 * sy,
      )
      ..cubicTo(
        564.658 * sx,
        177.837 * sy,
        563.776 * sx,
        178.008 * sy,
        562.85 * sx,
        178.008 * sy,
      )
      ..lineTo(187.55 * sx, 178.008 * sy)
      ..cubicTo(
        186.624 * sx,
        178.008 * sy,
        185.742 * sx,
        177.837 * sy,
        184.903 * sx,
        177.496 * sy,
      )
      ..cubicTo(
        184.056 * sx,
        177.152 * sy,
        183.308 * sx,
        176.656 * sy,
        182.657 * sx,
        176.008 * sy,
      )
      ..lineTo(162.347 * sx, 155.985 * sy)
      ..cubicTo(
        161.7 * sx,
        155.341 * sy,
        160.953 * sx,
        154.85 * sy,
        160.102 * sx,
        154.508 * sy,
      )
      ..cubicTo(
        159.259 * sx,
        154.169 * sy,
        158.372 * sx,
        154 * sy,
        157.44 * sx,
        154 * sy,
      )
      ..lineTo(0, 154 * sy)
      ..close();
  }

  Path _buildLinePath2(Size size) {
    final sx = size.width / _svgW;
    final sy = size.height / _svgH;
    return Path()
      ..moveTo(0, 152 * sy)
      ..lineTo(157.5 * sx, 152 * sy)
      ..cubicTo(
        158.637 * sx,
        152 * sy,
        159.711 * sx,
        152.208 * sy,
        160.723 * sx,
        152.623 * sy,
      )
      ..cubicTo(
        161.738 * sx,
        153.039 * sy,
        162.646 * sx,
        153.646 * sy,
        163.447 * sx,
        154.444 * sy,
      )
      ..lineTo(183.747 * sx, 174.464 * sy)
      ..cubicTo(
        184.243 * sx,
        174.958 * sy,
        184.832 * sx,
        175.338 * sy,
        185.517 * sx,
        175.607 * sy,
      )
      ..cubicTo(
        186.186 * sx,
        175.869 * sy,
        186.88 * sx,
        176 * sy,
        187.6 * sx,
        176 * sy,
      )
      ..lineTo(562.8 * sx, 176 * sy)
      ..cubicTo(
        563.508 * sx,
        176 * sy,
        564.208 * sx,
        175.85 * sy,
        564.899 * sx,
        175.55 * sy,
      )
      ..cubicTo(
        565.564 * sx,
        175.261 * sy,
        566.149 * sx,
        174.866 * sy,
        566.652 * sx,
        174.365 * sy,
      )
      ..lineTo(586.753 * sx, 154.444 * sy)
      ..cubicTo(
        587.548 * sx,
        153.653 * sy,
        588.471 * sx,
        153.046 * sy,
        589.524 * sx,
        152.624 * sy,
      )
      ..cubicTo(
        590.562 * sx,
        152.208 * sy,
        591.654 * sx,
        152 * sy,
        592.8 * sx,
        152 * sy,
      )
      ..lineTo(750 * sx, 152 * sy)
      ..lineTo(750 * sx, 151 * sy)
      ..lineTo(592.8 * sx, 151 * sy)
      ..cubicTo(
        591.525 * sx,
        151 * sy,
        590.309 * sx,
        151.232 * sy,
        589.151 * sx,
        151.696 * sy,
      )
      ..cubicTo(
        587.974 * sx,
        152.168 * sy,
        586.939 * sx,
        152.848 * sy,
        586.048 * sx,
        153.735 * sy,
      )
      ..lineTo(565.947 * sx, 173.656 * sy)
      ..cubicTo(
        565.533 * sx,
        174.068 * sy,
        565.051 * sx,
        174.394 * sy,
        564.501 * sx,
        174.633 * sy,
      )
      ..cubicTo(
        563.936 * sx,
        174.878 * sy,
        563.369 * sx,
        175 * sy,
        562.8 * sx,
        175 * sy,
      )
      ..lineTo(187.6 * sx, 175 * sy)
      ..cubicTo(
        187.006 * sx,
        175 * sy,
        186.434 * sx,
        174.892 * sy,
        185.883 * sx,
        174.676 * sy,
      )
      ..cubicTo(
        185.326 * sx,
        174.457 * sy,
        184.849 * sx,
        174.15 * sy,
        184.453 * sx,
        173.756 * sy,
      )
      ..lineTo(164.153 * sx, 153.736 * sy)
      ..cubicTo(
        163.256 * sx,
        152.843 * sy,
        162.239 * sx,
        152.164 * sy,
        161.102 * sx,
        151.698 * sy,
      )
      ..cubicTo(
        159.969 * sx,
        151.233 * sy,
        158.768 * sx,
        151 * sy,
        157.5 * sx,
        151 * sy,
      )
      ..lineTo(0, 151 * sy)
      ..close();
  }

  void _drawBottomDecoLeft(Canvas canvas, Size size, Paint paint) {
    final sx = size.width / _svgW;
    final sy = size.height / _svgH;
    for (var i = 0; i < 6; i++) {
      final x0 = (12 + 26 * i) * sx;
      final x1 = (25.7529 + 26 * i) * sx;
      final x2 = (38 + 26 * i) * sx;
      final p = Path()
        ..moveTo(x1, 180 * sy)
        ..lineTo(x0, 168 * sy)
        ..lineTo(x1, 168 * sy)
        ..lineTo(x2, 180 * sy)
        ..close();
      canvas.drawPath(p, paint);
    }
  }

  void _drawBottomDecoRight(Canvas canvas, Size size, Paint paint) {
    final sx = size.width / _svgW;
    final sy = size.height / _svgH;
    for (var i = 0; i < 6; i++) {
      final x0 = (738 - 26 * i) * sx;
      final x1 = (724.247 - 26 * i) * sx;
      final x2 = (712 - 26 * i) * sx;
      final p = Path()
        ..moveTo(x1, 180 * sy)
        ..lineTo(x0, 168 * sy)
        ..lineTo(x1, 168 * sy)
        ..lineTo(x2, 180 * sy)
        ..close();
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

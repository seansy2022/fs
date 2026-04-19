import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

import '../../core/models/ui_models.dart';

/// A generic bottom navigation bar.
///
/// [tabs] is a list of [UiNavTab] describing each tab.
/// [activeIndex] is the index of the currently active tab.
/// For RC apps, tab index 1 (菜单) is treated as active when [activeIndex]
/// is not 0 (首页) or 2 (蓝牙) — mirroring the original Screen-based logic.
/// The caller controls this via [activeIndex].
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onNavigate,
  });

  final List<UiNavTab> tabs;
  final int activeIndex;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _TabBarPainter())),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 2, 0, 3),
            child: Row(
              children: tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final tab = entry.value;
                final active = i == activeIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onNavigate(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: SvgPicture.asset(
                            active ? tab.activeIconAsset : tab.iconAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            color: active ? AppColors.text : AppColors.outline,
                            fontSize: AppFonts.s9,
                            letterSpacing: 0.5,
                            fontWeight: AppFonts.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarPainter extends CustomPainter {
  static const double _svgW = 750;
  static const double _svgH = 190;

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
      path.shift(Offset(0, -0 * sy)),
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
    const colors = [
      Color(0xFF7DA2CE),
      Color(0xFF00C6FF),
      Color(0xFF92FE9D),
      Color(0xFF00C8FF),
      Color(0xFF7DA2CE),
    ];
    const stops = [0.0, 0.3334, 0.5092, 0.678, 1.0];
    canvas.drawPath(
      line1,
      Paint()
        ..shader = const LinearGradient(
          colors: colors,
          stops: stops,
        ).createShader(Rect.fromLTWH(0, 7 * sy, size.width, 1)),
    );
    canvas.drawPath(
      line2,
      Paint()
        ..shader = const LinearGradient(
          colors: colors,
          stops: stops,
        ).createShader(Rect.fromLTWH(0, 10.5 * sy, size.width, 1)),
    );
  }

  Path _buildMainPath(Size size) {
    final sx = size.width / _svgW;
    final sy = size.height / _svgH;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(169.42 * sx, 0)
      ..cubicTo(170.52 * sx, 0, 171.52 * sx, 0.4 * sy, 172.22 * sx, 1.2 * sy)
      ..lineTo(181.82 * sx, 10.8 * sy)
      ..cubicTo(
        182.62 * sx,
        11.6 * sy,
        183.62 * sx,
        12 * sy,
        184.62 * sx,
        12 * sy,
      )
      ..lineTo(565.18 * sx, 12 * sy)
      ..cubicTo(
        566.28 * sx,
        12 * sy,
        567.28 * sx,
        11.6 * sy,
        567.98 * sx,
        10.8 * sy,
      )
      ..lineTo(577.48 * sx, 1.3 * sy)
      ..cubicTo(
        578.28 * sx,
        0.5 * sy,
        579.28 * sx,
        0.1 * sy,
        580.28 * sx,
        0.1 * sy,
      )
      ..lineTo(750 * sx, 0.1 * sy)
      ..lineTo(750 * sx, 190 * sy)
      ..lineTo(0, 190 * sy)
      ..close();
  }

  Path _buildLinePath1(Size size) {
    final sx = size.width / _svgW;
    final sy = size.height / _svgH;
    return Path()
      ..moveTo(0, 2 * sy)
      ..lineTo(169.42 * sx, 2 * sy)
      ..cubicTo(
        169.844 * sx,
        2 * sy,
        170.231 * sx,
        2.07388 * sy,
        170.582 * sx,
        2.22163 * sy,
      )
      ..cubicTo(
        170.929 * sx,
        2.3675 * sy,
        171.224 * sx,
        2.5798 * sy,
        171.467 * sx,
        2.85855 * sy,
      )
      ..lineTo(181.113 * sx, 12.5071 * sy)
      ..cubicTo(
        181.599 * sx,
        12.9934 * sy,
        182.147 * sx,
        13.3649 * sy,
        182.757 * sx,
        13.6216 * sy,
      )
      ..cubicTo(
        183.356 * sx,
        13.8739 * sy,
        183.977 * sx,
        14 * sy,
        184.62 * sx,
        14 * sy,
      )
      ..lineTo(565.18 * sx, 14 * sy)
      ..cubicTo(
        565.873 * sx,
        14 * sy,
        566.519 * sx,
        13.8739 * sy,
        567.118 * sx,
        13.6216 * sy,
      )
      ..cubicTo(
        567.737 * sx,
        13.361 * sy,
        568.268 * sx,
        12.982 * sy,
        568.709 * sx,
        12.4847 * sy,
      )
      ..lineTo(578.187 * sx, 3.00711 * sy)
      ..cubicTo(
        578.489 * sx,
        2.70551 * sy,
        578.824 * sx,
        2.47702 * sy,
        579.193 * sx,
        2.32163 * sy,
      )
      ..cubicTo(
        579.544 * sx,
        2.17388 * sy,
        579.906 * sx,
        2.1 * sy,
        580.28 * sx,
        2.1 * sy,
      )
      ..lineTo(750.001 * sx, 2 * sy)
      ..lineTo(750 * sx, 0)
      ..lineTo(580.279 * sx, 0.1 * sy)
      ..cubicTo(
        579.636 * sx,
        0.1 * sy,
        579.016 * sx,
        0.226124 * sy,
        578.417 * sx,
        0.478372 * sy,
      )
      ..cubicTo(
        577.807 * sx,
        0.735077 * sy,
        577.259 * sx,
        1.10657 * sy,
        576.773 * sx,
        1.59284 * sy,
      )
      ..lineTo(567.273 * sx, 11.0929 * sy)
      ..cubicTo(
        566.983 * sx,
        11.4202 * sy,
        566.688 * sx,
        11.6325 * sy,
        566.342 * sx,
        11.7784 * sy,
      )
      ..cubicTo(
        565.991 * sx,
        11.9261 * sy,
        565.604 * sx,
        12 * sy,
        565.18 * sx,
        12 * sy,
      )
      ..lineTo(184.62 * sx, 12 * sy)
      ..cubicTo(
        184.246 * sx,
        12 * sy,
        183.884 * sx,
        11.9261 * sy,
        183.533 * sx,
        11.7784 * sy,
      )
      ..cubicTo(
        183.164 * sx,
        11.623 * sy,
        182.829 * sx,
        11.3945 * sy,
        182.527 * sx,
        11.0929 * sy,
      )
      ..lineTo(172.949 * sx, 1.51494 * sy)
      ..cubicTo(
        172.507 * sx,
        1.01782 * sy,
        171.977 * sx,
        0.638968 * sy,
        171.358 * sx,
        0.378373 * sy,
      )
      ..cubicTo(
        170.759 * sx,
        0.126124 * sy,
        170.113 * sx,
        0 * sy,
        169.42 * sx,
        0 * sy,
      )
      ..lineTo(0, 0)
      ..close();
  }

  Path _buildLinePath2(Size size) {
    final sx = size.width / _svgW;
    final sy = size.height / _svgH;
    return Path()
      ..moveTo(0, 5 * sy)
      ..lineTo(169 * sx, 5 * sy)
      ..cubicTo(
        169.395 * sx,
        5 * sy,
        169.744 * sx,
        5.15118 * sy,
        170.046 * sx,
        5.45355 * sy,
      )
      ..lineTo(180.246 * sx, 15.6536 * sy)
      ..cubicTo(
        180.687 * sx,
        16.0937 * sy,
        181.182 * sx,
        16.4294 * sy,
        181.731 * sx,
        16.6608 * sy,
      )
      ..cubicTo(
        182.268 * sx,
        16.8869 * sy,
        182.825 * sx,
        17 * sy,
        183.4 * sx,
        17 * sy,
      )
      ..lineTo(566.4 * sx, 17 * sy)
      ..cubicTo(
        567.026 * sx,
        17 * sy,
        567.607 * sx,
        16.8869 * sy,
        568.144 * sx,
        16.6608 * sy,
      )
      ..cubicTo(
        568.697 * sx,
        16.4277 * sy,
        569.171 * sx,
        16.0883 * sy,
        569.565 * sx,
        15.6424 * sy,
      )
      ..lineTo(579.654 * sx, 5.55355 * sy)
      ..cubicTo(
        579.831 * sx,
        5.37634 * sy,
        580.011 * sx,
        5.23931 * sy,
        580.195 * sx,
        5.14246 * sy,
      )
      ..cubicTo(
        580.376 * sx,
        5.04749 * sy,
        580.544 * sx,
        5 * sy,
        580.7 * sx,
        5 * sy,
      )
      ..lineTo(750 * sx, 5 * sy)
      ..lineTo(750 * sx, 4 * sy)
      ..lineTo(580.7 * sx, 4 * sy)
      ..cubicTo(
        580.379 * sx,
        4 * sy,
        580.056 * sx,
        4.08585 * sy,
        579.73 * sx,
        4.25754 * sy,
      )
      ..cubicTo(
        579.457 * sx,
        4.40145 * sy,
        579.195 * sx,
        4.59775 * sy,
        578.946 * sx,
        4.84645 * sy,
      )
      ..lineTo(568.846 * sx, 14.9464 * sy)
      ..cubicTo(
        568.529 * sx,
        15.3073 * sy,
        568.173 * sx,
        15.5635 * sy,
        567.756 * sx,
        15.7392 * sy,
      )
      ..cubicTo(
        567.343 * sx,
        15.9131 * sy,
        566.891 * sx,
        16 * sy,
        566.4 * sx,
        16 * sy,
      )
      ..lineTo(183.4 * sx, 16 * sy)
      ..cubicTo(
        182.959 * sx,
        16 * sy,
        182.532 * sx,
        15.9131 * sy,
        182.119 * sx,
        15.7392 * sy,
      )
      ..cubicTo(
        181.69 * sx,
        15.5585 * sy,
        181.301 * sx,
        15.2942 * sy,
        180.954 * sx,
        14.9464 * sy,
      )
      ..lineTo(170.754 * sx, 4.74645 * sy)
      ..cubicTo(
        170.511 * sx,
        4.50331 * sy,
        170.237 * sx,
        4.31755 * sy,
        169.932 * sx,
        4.18918 * sy,
      )
      ..cubicTo(
        169.632 * sx,
        4.06306 * sy,
        169.321 * sx,
        4 * sy,
        169 * sx,
        4 * sy,
      )
      ..lineTo(0, 4 * sy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

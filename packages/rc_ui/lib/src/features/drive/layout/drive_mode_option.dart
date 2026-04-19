import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/src/core/app_assets.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

import 'drive_layout.dart';

class DriveModeOption extends StatefulWidget {
  const DriveModeOption({
    super.key,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final DriveLayout mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<DriveModeOption> createState() => _DriveModeOptionState();
}

class _DriveModeOptionState extends State<DriveModeOption> {
  bool _isPressed = false;

  String get _asset => switch (widget.mode) {
    DriveLayout.front => AppAssets.driveModeFront,
    DriveLayout.rear => AppAssets.driveModeRear,
    DriveLayout.mixed => AppAssets.driveModeMixed,
  };

  String get _label => switch (widget.mode) {
    DriveLayout.front => '前驱',
    DriveLayout.rear => '后驱',
    DriveLayout.mixed => '前后混驱',
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
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          duration: const Duration(milliseconds: 50),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
            gradient: widget.selected
                ? AppGradients.v20
                : AppGradients.surfaceFade,
          ),
          foregroundDecoration: const _DriveModeBorderDecoration(),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 50),
            opacity: _isPressed ? 0.9 : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 70,
                  child: SvgPicture.asset(_asset, fit: BoxFit.contain),
                ),
                const SizedBox(height: 4),
                Text(
                  _label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 12,
                    // fontWeight: AppFonts.w400,
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

class _DriveModeBorderDecoration extends Decoration {
  const _DriveModeBorderDecoration();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DriveModeBorderPainter();
}

class _DriveModeBorderPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    if (cfg.size == null) return;
    final rect = offset & cfg.size!;
    final border = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      const Radius.circular(AppDimens.radiusL),
    );

    canvas.save();
    canvas.clipRRect(border);
    final innerShadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = const Color(0xA30072FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(border.inflate(2.0), innerShadowPaint);
    canvas.restore();

    canvas.drawRRect(
      border,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..shader = AppGradients.metricBorder.createShader(rect),
    );
  }
}

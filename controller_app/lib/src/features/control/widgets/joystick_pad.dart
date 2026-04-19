import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

enum PadAxis { horizontal, vertical }

class AxisPad extends StatelessWidget {
  const AxisPad({
    super.key,
    required this.title,
    required this.value,
    required this.axis,
    required this.onChanged,
    required this.onReleased,
  });

  final String title;
  final double value;
  final PadAxis axis;
  final ValueChanged<double> onChanged;
  final VoidCallback onReleased;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _handle(details.localPosition, size),
          onPanUpdate: (details) => _handle(details.localPosition, size),
          onPanEnd: (_) => onReleased(),
          onPanCancel: onReleased,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF233854)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 14,
                  left: 14,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: AppFonts.s14,
                      fontWeight: AppFonts.w700,
                    ),
                  ),
                ),
                Container(
                  width: size * 0.74,
                  height: size * 0.74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF34506D)),
                  ),
                ),
                Container(
                  width: axis == PadAxis.horizontal ? size * 0.6 : 2,
                  height: axis == PadAxis.vertical ? size * 0.6 : 2,
                  color: const Color(0xFF34506D),
                ),
                Transform.translate(
                  offset: axis == PadAxis.horizontal
                      ? Offset(value * size * 0.26, 0)
                      : Offset(0, -value * size * 0.26),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.primary,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x550072FF),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handle(Offset localPosition, double size) {
    final center = Offset(size / 2, size / 2);
    final delta = localPosition - center;
    final nextValue = axis == PadAxis.horizontal
        ? (delta.dx / (size * 0.26)).clamp(-1.0, 1.0)
        : (-delta.dy / (size * 0.26)).clamp(-1.0, 1.0);
    onChanged(nextValue);
  }
}

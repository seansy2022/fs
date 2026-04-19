
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

import 'package:rc_ui/src/elements/container/panel.dart';
import 'package:rc_ui/src/elements/button/svg_button.dart';

class Mark {
  const Mark({required this.value, required this.label, this.primary = false});
  final int value;
  final String label;
  final bool primary;
}

class ValueControl extends StatelessWidget {
  const ValueControl({
    super.key,
    required this.label,
    this.subLabel,
    required this.value,
    required this.onChange,
    this.min = -120,
    this.max = 120,
    this.step = 1,
    this.unit = '',
    this.marks = const [],
    this.showButtons = true,
    this.showPresets = false,
  });

  final String label;
  final String? subLabel;
  final int value;
  final int min;
  final int max;
  final int step;
  final String unit;
  final List<Mark> marks;
  final ValueChanged<int> onChange;
  final bool showButtons;
  final bool showPresets;

  int _clamp(int value) => value.clamp(min, max);

  void _updateByDx(double dx, double width) {
    final ratio = (dx / width).clamp(0.0, 1.0);
    final raw = min + ((max - min) * ratio).round();
    final stepped = ((raw / step).round() * step);
    onChange(_clamp(stepped));
  }

  @override
  Widget build(BuildContext context) {
    final percent = (value - min) / (max - min);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subLabel != null)
                      Text(
                        subLabel!,
                        style: const TextStyle(
                          color: AppColors.outline,
                          fontSize: AppFonts.s10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: AppFonts.s20,
                        fontWeight: AppFonts.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$value$unit',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: AppFonts.w700,
                  fontSize: AppFonts.s16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          if (showPresets) ...[
            Row(
              children: [
                _preset('-100', () => onChange(-100)),
                const SizedBox(width: AppDimens.gapM),
                _preset('0', () => onChange(0), center: true),
                const SizedBox(width: AppDimens.gapM),
                _preset('+100', () => onChange(100)),
              ],
            ),
            const SizedBox(height: AppDimens.gapM),
          ],
          Row(
            children: [
              if (showButtons) ...[
                iconButton(
                  icon: Icons.remove,
                  onTap: () => onChange(_clamp(value - step)),
                ),
                const SizedBox(width: AppDimens.gapM),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanDown: (d) =>
                          _updateByDx(d.localPosition.dx, constraints.maxWidth),
                      onPanUpdate: (d) =>
                          _updateByDx(d.localPosition.dx, constraints.maxWidth),
                      child: SizedBox(
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHighest,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(11, (index) {
                                    final isMajor =
                                        index == 0 || index == 5 || index == 10;
                                    return Container(
                                      width: 2,
                                      height: isMajor ? 20 : 8,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            isMajor
                                                ? AppColors.outline
                                                : AppColors.line,
                                            AppColors.bg,
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                            Positioned(
                              left: constraints.maxWidth / 2 - 1,
                              top: 12,
                              bottom: 12,
                              child: Container(
                                width: 2,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [AppColors.outline, AppColors.bg],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: value >= 0
                                  ? constraints.maxWidth / 2
                                  : constraints.maxWidth * percent,
                              right: value >= 0
                                  ? constraints.maxWidth * (1 - percent)
                                  : constraints.maxWidth / 2,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment(percent * 2 - 1, 0),
                              child: Container(
                                width: 22,
                                height: 38,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primary,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.onPrimary,
                                    width: 1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xAA0072FF),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _GripLine(),
                                    _GripLine(),
                                    _GripLine(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (showButtons) ...[
                const SizedBox(width: AppDimens.gapM),
                iconButton(
                  icon: Icons.add,
                  onTap: () => onChange(_clamp(value + step)),
                ),
              ],
            ],
          ),
          if (marks.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: marks
                  .map(
                    (m) => Text(
                      m.label,
                      style: TextStyle(
                        color: m.primary
                            ? AppColors.primary
                            : AppColors.outline,
                        fontSize: AppFonts.s10,
                        fontWeight: m.primary
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _preset(String text, VoidCallback onTap, {bool center = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: center
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: center ? const Color(0xFF0072FF) : const Color(0x990072FF),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: center ? AppColors.primary : AppColors.text,
              fontWeight: AppFonts.w700,
              fontSize: AppFonts.s11,
            ),
          ),
        ),
      ),
    );
  }
}

class _GripLine extends StatelessWidget {
  const _GripLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

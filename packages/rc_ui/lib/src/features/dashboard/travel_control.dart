import 'package:flutter/material.dart';
import 'package:rc_ui/src/elements/button/rc_icon_button.dart';
import '../../core/theme/app_theme.dart';

class TravelControl extends StatelessWidget {
  const TravelControl({
    super.key,
    required this.label,
    this.subLabel,
    required this.lValue,
    required this.rValue,
    required this.onLChange,
    required this.onRChange,
    this.min = 0,
    this.max = 120,
  });

  final String label;
  final String? subLabel;
  final int lValue;
  final int rValue;
  final int min;
  final int max;
  final ValueChanged<int> onLChange;
  final ValueChanged<int> onRChange;

  int _clamp(int value) => value.clamp(min, max);

  @override
  Widget build(BuildContext context) {
    final lRatio = lValue / max;
    final rRatio = rValue / max;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xCC0072FF)),
        boxShadow: const [
          BoxShadow(color: Color(0x660072FF), blurRadius: 8, spreadRadius: -2),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: AppFonts.s16,
                        fontWeight: AppFonts.w700,
                      ),
                    ),
                    if (subLabel != null)
                      Text(
                        subLabel!,
                        style: const TextStyle(
                          color: AppColors.outline,
                          fontSize: AppFonts.s10,
                          letterSpacing: 1.0,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  _limit('L-LIMIT', lValue),
                  const SizedBox(width: 16),
                  _limit('R-LIMIT', rValue),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          Row(
            children: [
              _stepGroup(
                onMinus: () => onLChange(_clamp(lValue - 1)),
                onPlus: () => onLChange(_clamp(lValue + 1)),
              ),
              const SizedBox(width: AppDimens.gapM),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x990072FF)),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(12, (index) {
                              final isMajor = index == 0 || index == 11;
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
                      const Positioned.fill(
                        child: Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Text(
                                    'L',
                                    style: TextStyle(
                                      color: Color(0x99465D7A),
                                      fontSize: AppFonts.s10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 1),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    'R',
                                    style: TextStyle(
                                      color: Color(0x99465D7A),
                                      fontSize: AppFonts.s10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor: lRatio,
                                child: Container(
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.primaryReverse,
                                    border: Border(
                                      right: BorderSide(
                                        color: AppColors.onPrimary.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 2,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [AppColors.outline, AppColors.bg],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: rRatio,
                                child: Container(
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.primary,
                                    border: Border(
                                      left: BorderSide(
                                        color: AppColors.onPrimary.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.gapM),
              _stepGroup(
                onMinus: () => onRChange(_clamp(rValue - 1)),
                onPlus: () => onRChange(_clamp(rValue + 1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _limit(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.outline,
            fontSize: AppFonts.s10,
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: AppFonts.s16,
            fontWeight: AppFonts.w700,
          ),
        ),
      ],
    );
  }

  Widget _stepGroup({
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x990072FF)),
      ),
      child: Row(
        children: [
          RCIconButton(
            plus: false,
            onTap: onMinus,
            size: 32,
            iconSize: 14,
          ),
          RCIconButton(
            plus: true,
            onTap: onPlus,
            size: 32,
            iconSize: 14,
          ),
        ],
      ),
    );
  }
}

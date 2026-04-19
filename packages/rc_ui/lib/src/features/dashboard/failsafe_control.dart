import 'package:flutter/material.dart';
import 'package:rc_ui/src/elements/button/rc_icon_button.dart';
import '../../core/theme/app_theme.dart';
import '../../components/forms/rc_multi_toggle.dart';

class FailsafeControl extends StatelessWidget {
  const FailsafeControl({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.active,
    required this.value,
    required this.onActiveChanged,
    required this.onValueChanged,
    this.min = -120,
    this.max = 120,
    this.step = 1,
  });

  final String channelId;
  final String channelName;
  final bool active;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<int> onValueChanged;

  int _clamp(int next) => next.clamp(min, max);

  void _updateByDx(double dx, double width) {
    final ratio = (dx / width).clamp(0.0, 1.0);
    final raw = min + ((max - min) * ratio).round();
    final stepped = ((raw / step).round() * step);
    onValueChanged(_clamp(stepped));
  }

  @override
  Widget build(BuildContext context) {
    final percent = (value - min) / (max - min);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$channelId $channelName',
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: AppFonts.s20,
                  fontWeight: AppFonts.w700,
                ),
              ),
              const Spacer(),
              RcMultiToggle<bool>(
                options: const [false, true],
                selected: active,
                onChanged: onActiveChanged,
              ),
              const Spacer(),
              Text(
                'L:$value%',
                style: const TextStyle(
                  color: AppColors.primaryBright,
                  fontSize: AppFonts.s20,
                  fontWeight: AppFonts.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              RCIconButton(
                plus: false,
                onTap: () => onValueChanged(_clamp(value - step)),
                size: 48,
                iconSize: 24,
              ),
              const SizedBox(width: 10),
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
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceHighest,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: constraints.maxWidth * (1 - percent),
                              child: Container(
                                height: 20,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryBright,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(11, (index) {
                                  final isMajor =
                                      index == 0 || index == 5 || index == 10;
                                  return Container(
                                    width: 2,
                                    height: isMajor ? 20 : 8,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.outline,
                                          AppColors.bg,
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            Positioned(
                              left: (constraints.maxWidth * percent - 20).clamp(
                                0,
                                constraints.maxWidth - 40,
                              ),
                              child: _thumb(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              RCIconButton(
                plus: true, 
                onTap: () => onValueChanged(_clamp(value + step)),
                size: 48,
                iconSize: 24,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$min', style: const TextStyle(color: AppColors.outline)),
                const Text('-100', style: TextStyle(color: AppColors.outline)),
                const Text('0', style: TextStyle(color: AppColors.outline)),
                const Text('100', style: TextStyle(color: AppColors.outline)),
                Text('$max', style: const TextStyle(color: AppColors.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.primary, AppColors.primaryBright],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.onPrimary),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [_Grip(), _Grip(), _Grip()],
      ),
    );
  }
}

class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../widgets/settings_workspace.dart';

class TankMixingPage extends ConsumerWidget {
  const TankMixingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsWorkspace(
      activeRoute: AppRoutes.tankMixing,
      onBack: () => Navigator.of(context).pop(),
      content: const TankMixingContent(),
    );
  }
}

class TankMixingContent extends ConsumerWidget {
  const TankMixingContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    final left = settings.trackMixLeft.round().clamp(-100, 100);
    final right = settings.trackMixRight.round().clamp(-100, 100);
    final forward = (((left > 0 ? left : 0) + (right > 0 ? right : 0)) / 2)
        .round();
    final backward = (((left < 0 ? -left : 0) + (right < 0 ? -right : 0)) / 2)
        .round();
    final leftTurn = (left < 0 ? -left : 0).round();
    final rightTurn = (right > 0 ? right : 0).round();
    final ratio = (((left.abs() + right.abs()) / 2).round()).clamp(0, 100);
    final direction = left.sign == right.sign ? 'SAME' : 'OPPOSITE';

    return Column(
      children: [
        SettingsStrip(
          height: 88,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '履带混控',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 28,
                    fontWeight: AppFonts.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: PrimaryButton(
                  text: '左转 ${left.round()}%',
                  type: PrimaryButtonType.normal,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                child: PrimaryButton(
                  text: '右转 ${right.round()}%',
                  type: PrimaryButtonType.normal,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SettingsStrip(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: TankControl(
              selectedChannel: 'CH3/CH4',
              ratio: ratio,
              direction: direction,
              forwardRatio: forward,
              backwardRatio: backward,
              leftRatio: leftTurn,
              rightRatio: rightTurn,
              onControlChange: (nextRatio, nextDirection) {
                if (nextDirection == 'OPPOSITE') {
                  final abs = nextRatio.abs().toDouble();
                  controller.updateTrackMix(left: -abs, right: abs);
                  return;
                }
                final same = nextRatio.toDouble();
                controller.updateTrackMix(left: same, right: same);
              },
            ),
          ),
        ),
      ],
    );
  }
}

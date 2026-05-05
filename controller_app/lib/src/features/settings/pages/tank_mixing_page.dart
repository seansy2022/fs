import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../controllers/settings_controller.dart';
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
    final forwardActive = left > 0 && right > 0;
    final backwardActive = left < 0 && right < 0;
    final leftActive = left < 0 && right > 0;
    final rightActive = left > 0 && right < 0;

    return Column(
      children: [
        _TankMixingPanel(
          forwardActive: forwardActive,
          backwardActive: backwardActive,
          leftActive: leftActive,
          rightActive: rightActive,
          leftTrackValue: left,
          rightTrackValue: right,
          onLeftValueChanged: (v) => controller.updateTrackMix(left: v.toDouble()),
          onRightValueChanged: (v) => controller.updateTrackMix(right: v.toDouble()),
          onForwardTap: () => _toggleForward(controller, forwardActive),
          onBackwardTap: () => _toggleBackward(controller, backwardActive),
          onLeftTap: () => _toggleLeft(controller, leftActive),
          onRightTap: () => _toggleRight(controller, rightActive),
        ),
      ],
    );
  }

  void _toggleForward(SettingsController controller, bool active) {
    if (active) {
      controller.updateTrackMix(left: 0, right: 0);
      return;
    }
    controller.updateTrackMix(left: 100, right: 100);
  }

  void _toggleBackward(SettingsController controller, bool active) {
    if (active) {
      controller.updateTrackMix(left: 0, right: 0);
      return;
    }
    controller.updateTrackMix(left: -100, right: -100);
  }

  void _toggleLeft(SettingsController controller, bool active) {
    if (active) {
      controller.updateTrackMix(left: 0, right: 0);
      return;
    }
    controller.updateTrackMix(left: -100, right: 100);
  }

  void _toggleRight(SettingsController controller, bool active) {
    if (active) {
      controller.updateTrackMix(left: 0, right: 0);
      return;
    }
    controller.updateTrackMix(left: 100, right: -100);
  }
}

class _TankMixingPanel extends StatelessWidget {
  const _TankMixingPanel({
    required this.forwardActive,
    required this.backwardActive,
    required this.leftActive,
    required this.rightActive,
    required this.leftTrackValue,
    required this.rightTrackValue,
    required this.onLeftValueChanged,
    required this.onRightValueChanged,
    required this.onForwardTap,
    required this.onBackwardTap,
    required this.onLeftTap,
    required this.onRightTap,
  });

  final bool forwardActive;
  final bool backwardActive;
  final bool leftActive;
  final bool rightActive;
  final int leftTrackValue;
  final int rightTrackValue;
  final ValueChanged<int> onLeftValueChanged;
  final ValueChanged<int> onRightValueChanged;
  final VoidCallback onForwardTap;
  final VoidCallback onBackwardTap;
  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF001024),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SidePair(
            label: '左转',
            active: leftActive,
            onTap: onLeftTap,
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 220,
                child: TankProgressTrack(value: leftTrackValue),
              ),
              const SizedBox(height: 8),
              _TrackValueEdit(
                value: leftTrackValue,
                onChanged: onLeftValueChanged,
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CenterRow(
                    leftLabel: '前进',
                    leftActive: forwardActive,
                    rightIsButton: true,
                    rightActive: forwardActive,
                    onTap: onForwardTap,
                  ),
                  const SizedBox(height:8),
                  SizedBox(
                    width: 100,
                    height: 130,
                    child: SvgPicture.asset(
                      AppAssets.tank,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CenterRow(
                    leftIsButton: true,
                    leftActive: backwardActive,
                    rightLabel: '后退',
                    rightActive: backwardActive,
                    onTap: onBackwardTap,
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 220,
                child: TankProgressTrack(
                  value: rightTrackValue,
                  flipX: true,
                ),
              ),
              const SizedBox(height: 8),
              _TrackValueEdit(
                value: rightTrackValue,
                onChanged: onRightValueChanged,
              ),
            ],
          ),
          const SizedBox(width: 12),
          _SidePair(
            label: '右转',
            active: rightActive,
            onTap: onRightTap,
          ),
        ],
      ),
    );
  }
}

class _TrackValueEdit extends StatelessWidget {
  const _TrackValueEdit({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  void _onTap(BuildContext context) {
    final controller = TextEditingController(text: value.toString());
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 220,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '输入数值 (%)',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: AppFonts.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                textAlign: TextAlign.center,
                maxLength: 4,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: AppFonts.w700,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  PrimaryButton(
                    text: '取消',
                    width: 80,
                    type: PrimaryButtonType.normal,
                    onTap: () => Navigator.of(ctx).pop(),
                  ),
                  PrimaryButton(
                    text: '确定',
                    width: 80,
                    onTap: () {
                      final text = controller.text.trim();
                      final parsed = int.tryParse(text);
                      if (parsed != null) {
                        onChanged(parsed.clamp(-100, 100));
                      }
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        width: 60,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x661B2D4D),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF0072FF), width: 0.5),
        ),
        child: Text(
          '$value%',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: AppFonts.w700,
          ),
        ),
      ),
    );
  }
}

class _SidePair extends StatelessWidget {
  const _SidePair({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MetricLabel(label: label),
          const SizedBox(height: 12),
          _RcToggleButton(active: active, onTap: onTap),
        ],
      ),
    );
  }
}

class _CenterRow extends StatelessWidget {
  const _CenterRow({
    this.leftLabel,
    this.leftActive = false,
    this.leftIsButton = false,
    this.rightLabel,
    this.rightActive = false,
    this.rightIsButton = false,
    required this.onTap,
  });

  final String? leftLabel;
  final bool leftActive;
  final bool leftIsButton;
  final String? rightLabel;
  final bool rightActive;
  final bool rightIsButton;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 110,
          child: leftIsButton
              ? Align(
                  alignment: Alignment.centerRight,
                  child: _RcToggleButton(active: leftActive, onTap: onTap),
                )
              : _MetricLabel(label: leftLabel!),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 110,
          child: rightIsButton
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: _RcToggleButton(active: rightActive, onTap: onTap),
                )
              : _MetricLabel(label: rightLabel!),
        ),
      ],
    );
  }
}

class _MetricLabel extends StatelessWidget {
  const _MetricLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: AppFonts.w600,
          ),
        ),
      ],
    );
  }
}

class _RcToggleButton extends StatelessWidget {
  const _RcToggleButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RCButton(
      onTap: onTap,
      active: active,
      enableRepeat: false,
      width: 74,
      height: 34,
      textWidget: Text(
        '${active ? 100 : 0}%',
        style: TextStyle(
          color: active ? AppColors.text : AppColors.textDim,
          fontSize: 11,
          fontWeight: AppFonts.w600,
        ),
      ),
    );
  }
}

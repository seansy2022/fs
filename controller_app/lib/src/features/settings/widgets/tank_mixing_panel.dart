import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

class TankMixingPanel extends StatelessWidget {
  const TankMixingPanel({
    super.key,
    required this.forwardValue,
    required this.leftTurnValue,
    required this.rightTurnValue,
    required this.backwardValue,
    required this.forwardSelected,
    required this.backwardSelected,
    required this.leftTurnSelected,
    required this.rightTurnSelected,
    required this.leftTrackValue,
    required this.rightTrackValue,
    required this.onForwardTap,
    required this.onBackwardTap,
    required this.onLeftTap,
    required this.onRightTap,
  });

  final int forwardValue;
  final int leftTurnValue;
  final int rightTurnValue;
  final int backwardValue;
  final bool forwardSelected;
  final bool backwardSelected;
  final bool leftTurnSelected;
  final bool rightTurnSelected;
  final int leftTrackValue;
  final int rightTrackValue;
  final VoidCallback onForwardTap;
  final VoidCallback onBackwardTap;
  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF001024),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SidePair(
              label: '左转',
              value: leftTurnValue,
              selected: leftTurnSelected,
              onTap: onLeftTap,
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 220,
              child: TankProgressTrack(value: leftTrackValue),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CenterRow(
                  label: '前进',
                  value: forwardValue,
                  selected: forwardSelected,
                  onTap: onForwardTap,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 98,
                  height: 126,
                  child: SvgPicture.asset(AppAssets.tank, fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                _CenterRow(
                  label: '后退',
                  value: backwardValue,
                  selected: backwardSelected,
                  onTap: onBackwardTap,
                  labelAfterButton: true,
                ),
              ],
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 220,
              child: TankProgressTrack(value: rightTrackValue, flipX: true),
            ),
            const SizedBox(width: 12),
            _SidePair(
              label: '右转',
              value: rightTurnValue,
              selected: rightTurnSelected,
              onTap: onRightTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidePair extends StatelessWidget {
  const _SidePair({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int value;
  final bool selected;
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
          _RcValueButton(value: value, selected: selected, onTap: onTap),
        ],
      ),
    );
  }
}

class _CenterRow extends StatelessWidget {
  const _CenterRow({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.labelAfterButton = false,
  });

  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;
  final bool labelAfterButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelAfterButton)
          const Opacity(opacity: 0, child: _MetricLabel(label: '前进'))
        else
          _MetricLabel(label: label),
        const SizedBox(width: 16),
        _RcValueButton(value: value, selected: selected, onTap: onTap),
        const SizedBox(width: 16),
        if (labelAfterButton)
          _MetricLabel(label: label)
        else
          const Opacity(opacity: 0, child: _MetricLabel(label: '后退')),
      ],
    );
  }
}

class _MetricLabel extends StatelessWidget {
  const _MetricLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 14,
        fontWeight: AppFonts.w600,
      ),
    );
  }
}

class _RcValueButton extends StatelessWidget {
  const _RcValueButton({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RCButton(
      onTap: onTap,
      active: selected,
      enableRepeat: false,
      width: 74,
      height: 34,
      textWidget: Text(
        '$value%',
        style: TextStyle(
          color: selected ? AppColors.text : AppColors.textDim,
          fontSize: 11,
          fontWeight: AppFonts.w600,
        ),
      ),
    );
  }
}

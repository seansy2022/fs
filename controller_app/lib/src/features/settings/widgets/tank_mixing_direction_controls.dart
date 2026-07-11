import 'package:flutter/material.dart';

import 'tank_mixing_value_control.dart';

/// 履带混控的左右方向输入区，可选叠加顶部开关。
class TankMixSidePair extends StatelessWidget {
  const TankMixSidePair({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.selected,
    required this.onTap,
    this.topButton,
  });

  final String label;
  final int value;
  final bool enabled;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? topButton;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TankMixMetricLabel(label: label),
              const SizedBox(height: 12),
              TankMixValueButton(
                value: value,
                enabled: enabled,
                selected: selected,
                onTap: onTap,
              ),
            ],
          ),
          if (topButton != null)
            Positioned(top: 0, right: 24, child: topButton!),
        ],
      ),
    );
  }
}

/// 履带混控的前进或后退输入行。
class TankMixCenterRow extends StatelessWidget {
  const TankMixCenterRow({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.selected,
    required this.onTap,
    this.labelAfterButton = false,
  });

  final String label;
  final int value;
  final bool enabled;
  final bool selected;
  final VoidCallback? onTap;
  final bool labelAfterButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelAfterButton)
          const Opacity(opacity: 0, child: TankMixMetricLabel(label: '前进'))
        else
          TankMixMetricLabel(label: label),
        const SizedBox(width: 16),
        TankMixValueButton(
          value: value,
          enabled: enabled,
          selected: selected,
          onTap: onTap,
        ),
        const SizedBox(width: 16),
        if (labelAfterButton)
          TankMixMetricLabel(label: label)
        else
          const Opacity(opacity: 0, child: TankMixMetricLabel(label: '后退')),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:rc_ui/src/components/progress/rc_progress_track.dart';
import 'package:rc_ui/src/components/value_control/control_value_widget.dart';

class TankTurnControl extends StatelessWidget {
  const TankTurnControl({
    super.key,
    required this.label,
    required this.valueText,
    this.onMinus,
    this.onPlus,
  });

  final String label;
  final String valueText;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return ControlValueWidget(
      label: label,
      valueText: valueText,
      style: ControlValueStyle.vertical,
      onMinus: onMinus,
      onPlus: onPlus,
    );
  }
}

class TankProgressTrack extends StatelessWidget {
  const TankProgressTrack({
    super.key,
    required this.topValue,
    required this.bottomValue,
    this.flipX = false,
  });

  final int topValue;
  final int bottomValue;
  final bool flipX;
  static const _displayMax = 120;
  static const _controlMax = 100;

  @override
  Widget build(BuildContext context) {
    return RcProgressTrack.vertical(
      value: 0,
      max: _displayMax,
      controlMax: _controlMax,
      absoluteLabels: true,
      reverseLabelSide: flipX,
      overlayVerticalLabels: true,
      positiveValue: topValue.toDouble(),
      negativeValue: bottomValue.toDouble(),
    );
  }
}

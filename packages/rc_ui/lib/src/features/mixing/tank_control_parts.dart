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
  const TankProgressTrack({super.key, required this.value, this.flipX = false});

  final int value;
  final bool flipX;
  static const _displayMax = 120;

  @override
  Widget build(BuildContext context) {
    return RcProgressTrack.vertical(
      value: value.clamp(-_displayMax, _displayMax).toDouble(),
      max: _displayMax,
      controlMax: _displayMax,
      absoluteLabels: true,
      reverseLabelSide: flipX,
      overlayVerticalLabels: true,
      showIntermediateLabels: false,
    );
  }
}

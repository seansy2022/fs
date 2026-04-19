import 'package:flutter/material.dart';
import 'package:rc_ui/src/elements/button/rc_icon_button.dart';
import 'rc_progress_track.dart';

class ControlProgressBar extends StatelessWidget {
  const ControlProgressBar({
    super.key,
    required this.value,
    this.leftValue,
    this.rightValue,
    this.max = 120,
    this.scale = 1,
    this.onMinus,
    this.onPlus,
    this.showSignedLabels = false,
    this.showUnsignedRange = false,
    this.highlightPlus = false,
    this.highlightTrack = true,
  });

  final double value;
  final int? leftValue;
  final int? rightValue;
  final int max;
  final double scale;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final bool showSignedLabels;
  final bool showUnsignedRange;
  final bool highlightPlus;
  final bool highlightTrack;

  @override
  Widget build(BuildContext context) {
    final button = 48 * scale;
    final gap = 18 * scale;
    final iconSize = button * 0.5;
    return SizedBox(
      // height: 62 * scale,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RCIconButton(
            plus: false,
            active: false,
            onTap: onMinus,
            size: button,
            iconSize: iconSize,
          ),
          SizedBox(width: gap),
          Expanded(
            child: RcProgressTrack.horizontal(
              value: value,
              leftValue: leftValue,
              rightValue: rightValue,
              max: max,
              showUnsignedRange: showUnsignedRange,
              highlightFill: highlightTrack,
              absoluteLabels: !showSignedLabels,
            ),
          ),
          SizedBox(width: gap),
          RCIconButton(
            plus: true,
            active: highlightPlus,
            onTap: onPlus,
            size: button,
            iconSize: iconSize,
          ),
        ],
      ),
    );
  }
}

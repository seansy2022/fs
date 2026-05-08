import 'package:flutter/material.dart';

import 'package:rc_ui/src/components/progress/named_control_progress_widget.dart';

class FourLunRatioControl extends StatelessWidget {
  const FourLunRatioControl({
    super.key,
    required this.ratio,
    required this.onRatioChange,
    this.title = 'Mix Ratio',
  });

  final int ratio;
  final ValueChanged<int> onRatioChange;
  final String title;

  int _clamp(int value) => value.clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    return NamedControlProgressWidget(
      title: title,
      status: '$ratio%',
      value: ratio.toDouble(),
      max: 100,
      showSignedLabels: false,
      showUnsignedRange: true,
      highlightPlus: false,
      horizontalPadding: 0,
      showBottomBorder: false,
      titleFontSize: 12,
      statusFontSize: 12,
      onMinus: () => onRatioChange(_clamp(ratio - 1)),
      onPlus: () => onRatioChange(_clamp(ratio + 1)),
    );
  }
}

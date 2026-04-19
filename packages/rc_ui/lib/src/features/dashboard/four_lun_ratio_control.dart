import 'package:flutter/material.dart';

import 'package:rc_ui/src/components/progress/named_control_progress_widget.dart';

class FourLunRatioControl extends StatelessWidget {
  const FourLunRatioControl({
    super.key,
    required this.ratio,
    required this.onRatioChange,
  });

  final int ratio;
  final ValueChanged<int> onRatioChange;

  int _clamp(int value) => value.clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    return NamedControlProgressWidget(
      title: '混控比率',
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

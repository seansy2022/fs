import 'package:flutter/material.dart';

import '../progress/named_control_progress_widget.dart';

class CurveSlider extends StatelessWidget {
  const CurveSlider({
    super.key,
    required this.title,
    required this.value,
    required this.onChange,
  });

  final String title;
  final int value;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return NamedControlProgressWidget(
      title: title,
      status: '$value%',
      value: value.toDouble(),
      max: 100,
      horizontalPadding: 0,
      showSignedLabels: true,
      highlightPlus: false,
      highlightTrack: true,
      onMinus: () => _step(-1),
      onPlus: () => _step(1),
    );
  }

  void _step(int delta) {
    onChange((value + delta).clamp(-100, 100));
  }
}

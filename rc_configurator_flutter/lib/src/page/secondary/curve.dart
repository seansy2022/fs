import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rc_ui/rc_ui.dart';
import '../../provider/curve_provider.dart';

class CurvePage extends ConsumerWidget {
  const CurvePage({super.key});

  static const curves = [
    ('Steering', '方向曲线'),
    ('Forward', '前进曲线'),
    ('Brake', '刹车曲线'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(curveProvider);
    final ctl = ref.read(curveProvider.notifier);
    final activeCurveName = _curveName(state.activeCurve);
    final isSteeringCurve = state.activeCurve == 'Steering';
    return ListView(
      padding: const EdgeInsets.all(AppDimens.gapL),
      children: [
        CurveTabs(
          curves: curves,
          active: state.activeCurve,
          onSelect: ctl.selectCurve,
        ),
        const SizedBox(height: 12),
        _curveSlider(
          title: activeCurveName,
          value: state.curveValue,
          showSignedLabels: !isSteeringCurve,
          onChange: ctl.updateCurveValue,
        ),
        const SizedBox(height: 12),
        RateChart(value: state.curveValue),
      ],
    );
  }

  Widget _curveSlider({
    required String title,
    required int value,
    required bool showSignedLabels,
    required ValueChanged<int> onChange,
  }) {
    return NamedControlProgressWidget(
      title: title,
      status: '$value%',
      value: value.toDouble(),
      max: 100,
      horizontalPadding: 0,
      showSignedLabels: showSignedLabels,
      highlightPlus: false,
      highlightTrack: true,
      onMinus: () => onChange((value - 1).clamp(-100, 100)),
      onPlus: () => onChange((value + 1).clamp(-100, 100)),
    );
  }

  String _curveName(String key) {
    for (final item in curves) {
      if (item.$1 == key) return item.$2;
    }
    return '曲线';
  }
}

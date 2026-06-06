import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rc_ui/rc_ui.dart';
import 'package:rc_configurator_flutter/l10n/app_localizations.dart';
import '../../provider/curve_provider.dart';

class CurvePage extends ConsumerWidget {
  const CurvePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final curves = <(String, String)>[
      ('Steering', l10n.steeringCurve),
      ('Forward', l10n.forwardCurve),
      ('Brake', l10n.brakeCurve),
    ];
    final state = ref.watch(curveProvider);
    final ctl = ref.read(curveProvider.notifier);
    final activeCurveName = _curveName(state.activeCurve, l10n);
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

  String _curveName(String key, AppLocalizations l10n) {
    if (key == 'Steering') return l10n.steeringCurve;
    if (key == 'Forward') return l10n.forwardCurve;
    if (key == 'Brake') return l10n.brakeCurve;
    return l10n.curve;
  }
}

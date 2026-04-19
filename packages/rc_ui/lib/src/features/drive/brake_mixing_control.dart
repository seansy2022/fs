import 'package:flutter/material.dart';

import 'package:rc_ui/src/components/cell/cell_rate_widget.dart';
import 'package:rc_ui/src/features/mixing/mixing_channel_row.dart';
import 'package:rc_ui/src/features/dashboard/rate_chart.dart';

class BrakeMixingControl extends StatelessWidget {
  const BrakeMixingControl({
    super.key,
    required this.selectedChannel,
    required this.ratio,
    required this.curve,
    required this.onRatioChange,
    required this.onCurveChange,
    this.onChannelTap,
  });

  final String selectedChannel;
  final int ratio;
  final int curve;
  final ValueChanged<int> onRatioChange;
  final ValueChanged<int> onCurveChange;
  final VoidCallback? onChannelTap;
  static const _fontSize = 12.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF001024),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Column(
        children: [
          MixingChannelRow(
            selectedChannel: selectedChannel,
            responsive: true,
            fontSize: _fontSize,
            onTap: onChannelTap,
          ),
          // const SizedBox(height: 8),
          CellRateWidget(
            title: '混控比率',
            value: ratio,
            showBorder: false,
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
            titleFontSize: _fontSize,
            valueFontSize: _fontSize,
            enablePressRepeat: true,
            onMinus: () => onRatioChange(_clampRatio(ratio - 1)),
            onPlus: () => onRatioChange(_clampRatio(ratio + 1)),
          ),
          // const SizedBox(height: 8),
          CellRateWidget(
            title: '混控曲线',
            value: curve,
            showBorder: false,
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
            titleFontSize: _fontSize,
            valueFontSize: _fontSize,
            enablePressRepeat: true,
            onMinus: () => onCurveChange(_clampCurve(curve - 1)),
            onPlus: () => onCurveChange(_clampCurve(curve + 1)),
          ),
          // const SizedBox(height: 8),
          RateChart(value: curve),
        ],
      ),
    );
  }

  int _clampRatio(int value) => value.clamp(0, 100);

  int _clampCurve(int value) => value.clamp(-100, 100);
}

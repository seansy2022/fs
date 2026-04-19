import 'package:flutter/material.dart';

import 'rate_chart_painter.dart';

class RateChart extends StatelessWidget {
  const RateChart({super.key, required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      // decoration: BoxDecoration(
      //   color: const Color(0x291B2D4D),
      //   borderRadius: BorderRadius.circular(12),
      // ),
      child: AspectRatio(
        aspectRatio: 656 / 647,
        child: CustomPaint(painter: RateChartPainter(value)),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class HomeMetric extends StatelessWidget {
  const HomeMetric({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final String unit;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final isDashPair = value == '-' && unit == '-';
    final valueColor = emphasize ? AppColors.onPrimary : AppColors.text;
    final valueStyle = TextStyle(
      color: valueColor,
      fontSize: AppFonts.s20,
      fontWeight: AppFonts.w700,
      shadows: const [Shadow(color: Color(0xFF0072FF), blurRadius: 12)],
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: AppDecorations.metricBase,
      foregroundDecoration: const MetricBorderDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: value, style: valueStyle),
                  TextSpan(
                    text: isDashPair ? ' $unit' : unit,
                    style: isDashPair
                        ? valueStyle
                        : valueStyle.copyWith(fontSize: AppFonts.s16),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // const SizedBox(height: 3),
          SizedBox(
            width: double.infinity,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7DA2CE),
                fontSize: AppFonts.s12,
                // fontWeight: AppFonts.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:rc_ui/src/components/progress/rc_progress_track.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class HomeCenterItem {
  const HomeCenterItem({required this.label, required this.state});
  final String label;
  final int state;
}

class HomeCenterWidget extends StatelessWidget {
  const HomeCenterWidget({
    super.key,
    this.items = const [
      HomeCenterItem(label: 'CH1', state: 0),
      HomeCenterItem(label: 'CH2', state: 0),
      HomeCenterItem(label: 'CH3', state: 0),
      HomeCenterItem(label: 'CH4', state: 0),
    ],
  });
  final List<HomeCenterItem> items;

  @override
  Widget build(BuildContext context) {
    final viewItems = items.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.metricBase,
      foregroundDecoration: const MetricBorderDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < viewItems.length; i++) ...[
            _row(viewItems[i]),
            if (i != viewItems.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _row(HomeCenterItem item) {
    final value = item.state.clamp(-120, 120).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // 自动对齐轨道中心
      children: [
        Text(item.label, style: _kLabel),
        const SizedBox(width: 6),
        Expanded(
          child: RcProgressTrack.dashboard(value: value),
        ),
      ],
    );
  }
}

const _kLabel = TextStyle(
  color: Color(0xFFEDF5FF),
  fontSize: AppFonts.s16,
  height: 1,
);

import 'package:flutter/material.dart';

import 'package:rc_ui/rc_ui.dart';
import '../../types.dart';

class DualRate extends StatelessWidget {
  const DualRate({
    super.key,
    required this.channels,
    required this.activeModel,
    required this.onUpdateDualRate,
  });

  final List<ChannelState> channels;
  final String activeModel;
  final void Function(String id, ChannelState next) onUpdateDualRate;

  @override
  Widget build(BuildContext context) {
    const labels = ['方向比率', '前进比率', '刹车比率'];
    return ListView(
      padding: const EdgeInsets.all(AppDimens.gapL),
      children: [
        ...channels.take(3).toList().asMap().entries.map((entry) {
          final ch = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.gapM),
            child: CellRateWidget(
              title: labels[entry.key],
              value: ch.dualRate,
              onMinus: () => _step(ch, -1),
              onPlus: () => _step(ch, 1),
            ),
          );
        }),
      ],
    );
  }

  void _step(ChannelState ch, int delta) {
    final next = (ch.dualRate + delta).clamp(0, 100);
    onUpdateDualRate(ch.id, ch.copyWith(dualRate: next));
  }
}

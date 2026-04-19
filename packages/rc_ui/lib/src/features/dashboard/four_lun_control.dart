import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'package:rc_ui/src/features/mixing/four_c_layout_grid.dart';
import 'four_lun_ratio_control.dart';
import 'package:rc_ui/src/features/mixing/mixing_channel_row.dart';

class FourLunControl extends StatelessWidget {
  const FourLunControl({
    super.key,
    required this.selectedChannel,
    required this.ratio,
    required this.direction,
    required this.onRatioChange,
    required this.onDirectionChange,
    required this.onLayoutChange,
    this.onChannelTap,
  });

  final String selectedChannel;
  final int ratio;
  final String direction;
  final ValueChanged<int> onRatioChange;
  final ValueChanged<String> onDirectionChange;
  final void Function(int ratio, String direction) onLayoutChange;
  final VoidCallback? onChannelTap;
  static const _fontSize = 12.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        children: [
          MixingChannelRow(
            selectedChannel: selectedChannel,
            fontSize: _fontSize,
            onTap: onChannelTap,
          ),
          const SizedBox(height: 16),
          FourLunRatioControl(ratio: ratio, onRatioChange: onRatioChange),
          const SizedBox(height: 16),
          FourCLayoutGrid(
            ratio: ratio,
            direction: direction,
            onModeChange: onLayoutChange,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

import 'package:rc_ui/src/components/progress/sides_control_progress_widget.dart';
import 'package:rc_ui/src/features/drive/layout/drive_layout.dart';
import 'package:rc_ui/src/features/drive/layout/drive_mode_row.dart';
import 'package:rc_ui/src/features/mixing/mixing_channel_row.dart';

class DriveMixingControl extends StatelessWidget {
  const DriveMixingControl({
    super.key,
    required this.selectedChannel,
    required this.frontRatio,
    required this.rearRatio,
    required this.leftSelected,
    required this.mode,
    required this.onRatioChange,
    required this.onModeChange,
    this.onChannelTap,
  });

  final String selectedChannel;
  final int frontRatio;
  final int rearRatio;
  final bool leftSelected;
  final DriveLayout mode;
  final void Function(int frontRatio, int rearRatio, bool leftSelected)
  onRatioChange;
  final ValueChanged<DriveLayout> onModeChange;
  final VoidCallback? onChannelTap;
  static const _fontSize = 12.0;

  void _adjust(int delta) {
    if (!leftSelected) {
      final nextRear = (rearRatio + delta).clamp(0, 100);
      onRatioChange(frontRatio, nextRear, false);
      return;
    }
    final nextFront = (frontRatio + delta).clamp(0, 100);
    onRatioChange(nextFront, rearRatio, true);
  }

  @override
  Widget build(BuildContext context) {
    final front = frontRatio.clamp(0, 100);
    final rear = rearRatio.clamp(0, 100);
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Column(
        children: [
          MixingChannelRow(
            selectedChannel: selectedChannel,
            fontSize: _fontSize,
            onTap: onChannelTap,
          ),
          const SizedBox(height: 16),
          SidesControlProgressWidget(
            title: '混控比率',
            leftStatus: 'F:$front%',
            rightStatus: 'R:$rear%',
            leftValue: front,
            rightValue: rear,
            max: 100,
            initialLeftSelected: leftSelected,
            leftSelected: leftSelected,
            titleLeading: true,
            statusButtonWidth: 60,
            statusFontSize: AppFonts.s11,
            titleFontSize: _fontSize,
            horizontalPadding: 0,
            showBottomBorder: false,
            onAdjust: (_, delta) => _adjust(delta),
            onSelectedChanged: (nextLeftSelected) =>
                onRatioChange(front, rear, nextLeftSelected),
          ),
          const SizedBox(height: 4),
          DriveModeRow(value: mode, onChanged: onModeChange),
        ],
      ),
    );
  }
}

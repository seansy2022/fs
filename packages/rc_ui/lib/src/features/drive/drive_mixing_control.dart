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
    required this.ratio,
    required this.mode,
    required this.onRatioChange,
    required this.onModeChange,
    this.onChannelTap,
  });

  final String selectedChannel;
  final int ratio;
  final DriveLayout mode;
  final ValueChanged<int> onRatioChange;
  final ValueChanged<DriveLayout> onModeChange;
  final VoidCallback? onChannelTap;
  static const _fontSize = 12.0;

  int _clamp(int value) => value.clamp(-100, 100);
  int _rearRatio() => ratio > 0 ? 100 - ratio : 100;
  int _frontRatio() => ratio < 0 ? 100 + ratio : 100;

  int _nextRatio({required bool adjustRear, required int delta}) {
    if (adjustRear) {
      final nextRear = (_rearRatio() + delta).clamp(0, 100);
      return _clamp(100 - nextRear);
    }
    final nextFront = (_frontRatio() + delta).clamp(0, 100);
    return _clamp(nextFront - 100);
  }

  @override
  Widget build(BuildContext context) {
    final rear = _rearRatio();
    final front = _frontRatio();
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
            initialLeftSelected: ratio < 0,
            titleLeading: true,
            statusButtonWidth: 60,
            statusFontSize: AppFonts.s11,
            titleFontSize: _fontSize,
            horizontalPadding: 0,
            showBottomBorder: false,
            onAdjust: (leftSelected, delta) {
              final adjustRear = !leftSelected;
              onRatioChange(_nextRatio(adjustRear: adjustRear, delta: delta));
            },
          ),
          const SizedBox(height: 4),
          DriveModeRow(value: mode, onChanged: onModeChange),
        ],
      ),
    );
  }
}

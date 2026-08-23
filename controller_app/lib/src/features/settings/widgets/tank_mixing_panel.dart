import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

import 'tank_mixing_direction_controls.dart';
import 'package:controller_app/src/core/localization/app_localizations.dart';

class TankMixingPanel extends StatelessWidget {
  const TankMixingPanel({
    super.key,
    required this.enabled,
    required this.onEnabledTap,
    required this.forwardValue,
    required this.leftTurnValue,
    required this.rightTurnValue,
    required this.backwardValue,
    required this.forwardSelected,
    required this.backwardSelected,
    required this.leftTurnSelected,
    required this.rightTurnSelected,
    required this.leftTrackValue,
    required this.rightTrackValue,
    required this.onForwardTap,
    required this.onBackwardTap,
    required this.onLeftTap,
    required this.onRightTap,
  });

  final bool enabled;
  final VoidCallback onEnabledTap;
  final int forwardValue;
  final int leftTurnValue;
  final int rightTurnValue;
  final int backwardValue;
  final bool forwardSelected;
  final bool backwardSelected;
  final bool leftTurnSelected;
  final bool rightTurnSelected;
  final int leftTrackValue;
  final int rightTrackValue;
  final VoidCallback onForwardTap;
  final VoidCallback onBackwardTap;
  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF001024),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: const Offset(30, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TankMixSidePair(
                  label: AppText.tr('左转'),
                  value: leftTurnValue,
                  enabled: enabled,
                  selected: enabled && leftTurnSelected,
                  onTap: enabled ? onLeftTap : null,
                  topButton: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppText.tr('履带混控：'),
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: AppFonts.w600,
                        ),
                      ),
                      RCButton(
                        key: const ValueKey<String>('tank-mixing-enabled'),
                        onTap: onEnabledTap,
                        active: enabled,
                        enableRepeat: false,
                        width: 56,
                        height: 28,
                        textWidget: Text(
                          AppText.tr(enabled ? '开启' : '关闭'),
                          style: TextStyle(
                            color: enabled ? AppColors.text : AppColors.textDim,
                            fontSize: 11,
                            fontWeight: AppFonts.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 220,
                  child: TankProgressTrack(value: leftTrackValue),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TankMixCenterRow(
                      label: AppText.tr('前进'),
                      value: forwardValue,
                      enabled: enabled,
                      selected: enabled && forwardSelected,
                      onTap: enabled ? onForwardTap : null,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 98,
                      height: 126,
                      child: SvgPicture.asset(
                        AppAssets.tank,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TankMixCenterRow(
                      label: AppText.tr('后退'),
                      value: backwardValue,
                      enabled: enabled,
                      selected: enabled && backwardSelected,
                      onTap: enabled ? onBackwardTap : null,
                      labelAfterButton: true,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 220,
                  child: TankProgressTrack(value: rightTrackValue, flipX: true),
                ),
                const SizedBox(width: 12),
                TankMixSidePair(
                  label: AppText.tr('右转'),
                  value: rightTurnValue,
                  enabled: enabled,
                  selected: enabled && rightTurnSelected,
                  onTap: enabled ? onRightTap : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

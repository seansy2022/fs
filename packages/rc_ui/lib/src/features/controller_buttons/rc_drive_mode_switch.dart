import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

enum RcDriveMode { low, high, park }

class RcDriveModeSwitch extends StatelessWidget {
  final RcDriveMode mode;
  final ValueChanged<RcDriveMode> onChanged;

  const RcDriveModeSwitch({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 154,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Row for Low/High speed buttons
          Positioned(
            left: 0,
            right: 0,
            top: 16,
            bottom: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RCIconButton(
                  icon: Icons.speed,
                  active: mode == RcDriveMode.low,
                  onTap: () => onChanged(RcDriveMode.low),
                  size: 64,
                  iconSize: 24,
                ),
                RCIconButton(
                  icon: Icons.fast_forward,
                  active: mode == RcDriveMode.high,
                  onTap: () => onChanged(RcDriveMode.high),
                  size: 64,
                  iconSize: 24,
                ),
              ],
            ),
          ),
          // Center "P" Button
          _DriveModeCenterButton(
            isSelected: mode == RcDriveMode.park,
            onTap: () => onChanged(RcDriveMode.park),
          ),
        ],
      ),
    );
  }
}

class _DriveModeCenterButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _DriveModeCenterButton({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.metricBorder,
        ),
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1B2D4D),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/p_w.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isSelected
                      ? const Color(0xFFFF3700)
                      : const Color(0xFF7DA2CE),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

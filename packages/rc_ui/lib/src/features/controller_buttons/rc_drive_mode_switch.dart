import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

enum RcDriveMode { low, high, park }

class RcDriveModeSwitch extends StatelessWidget {
  static const _switchWidth = 154.0;
  static const _switchHeight = 48.0;
  static const _sideButtonWidth = 63.0;
  static const _sideButtonHeight = 32.0;
  static const _middleMaskWidth = 28.0;

  final RcDriveMode mode;
  final ValueChanged<RcDriveMode> onChanged;
  final String lowLabel;
  final String highLabel;

  const RcDriveModeSwitch({
    super.key,
    required this.mode,
    required this.onChanged,
    this.lowLabel = 'Low Speed',
    this.highLabel = 'High Speed',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _switchWidth,
      height: _switchHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DriveModeTextButton(
                label: lowLabel,
                isSelected: mode == RcDriveMode.low,
                onTap: () => onChanged(RcDriveMode.low),
              ),
              const SizedBox(width: _middleMaskWidth),
              _DriveModeTextButton(
                label: highLabel,
                isSelected: mode == RcDriveMode.high,
                onTap: () => onChanged(RcDriveMode.high),
              ),
            ],
          ),
          _DriveModeCenterButton(
            isSelected: mode == RcDriveMode.park,
            onTap: () => onChanged(RcDriveMode.park),
          ),
        ],
      ),
    );
  }
}

class _DriveModeTextButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DriveModeTextButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RCButton(
      onTap: onTap,
      active: isSelected,
      enableRepeat: false,
      width: RcDriveModeSwitch._sideButtonWidth,
      height: RcDriveModeSwitch._sideButtonHeight,
      padding: EdgeInsets.zero,
      borderRadius: AppDimens.squareButtonRadius,
      textWidget: Text(
        label,
        style: TextStyle(
          fontSize: AppFonts.s14,
          fontWeight: AppFonts.w600,
          color: isSelected ? AppColors.onPrimary : const Color(0xFF7DA2CE),
        ),
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
    final textColor = isSelected
        ? const Color(0xFFFF3700)
        : const Color(0xFF7DA2CE);
    final backgroundColor = const Color(0xFF1B2D4D);

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
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
            ),
            child: Center(
              child: Text(
                'P',
                style: TextStyle(
                  fontSize: AppFonts.s20,
                  fontWeight: AppFonts.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

class AuxControlButtonViewData {
  const AuxControlButtonViewData({
    required this.label,
    required this.onTap,
    required this.key,
    required this.active,
    this.flashOnTap = false,
  });

  final String label;
  final VoidCallback onTap;
  final Key key;
  final bool active;
  final bool flashOnTap;
}

class ControlAuxActionPanel extends StatelessWidget {
  const ControlAuxActionPanel({super.key, required this.auxButtons});

  static const buttonWidth = 62.0;
  static const buttonHeight = 32.0;
  static const itemGap = 8.0;
  static const visibleButtonWidthFactor = 3.5;

  final List<AuxControlButtonViewData> auxButtons;

  @override
  Widget build(BuildContext context) {
    final visibleWidth = buttonWidth * visibleButtonWidthFactor;
    final visibleGaps = itemGap * (visibleButtonWidthFactor - 1);
    final viewportWidth = auxButtons.isEmpty ? 0.0 : visibleWidth + visibleGaps;
    return SizedBox(
      width: viewportWidth,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (
              var itemIndex = 0;
              itemIndex < auxButtons.length;
              itemIndex++
            ) ...[
              if (itemIndex > 0) const SizedBox(width: itemGap),
              _AuxActionButton(
                key: auxButtons[itemIndex].key,
                label: auxButtons[itemIndex].label,
                onTap: auxButtons[itemIndex].onTap,
                active: auxButtons[itemIndex].active,
                flashOnTap: auxButtons[itemIndex].flashOnTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuxActionButton extends StatefulWidget {
  const _AuxActionButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.active,
    required this.flashOnTap,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool flashOnTap;

  @override
  State<_AuxActionButton> createState() => _AuxActionButtonState();
}

class _AuxActionButtonState extends State<_AuxActionButton> {
  bool _flashActive = false;

  Future<void> _handleTap() async {
    widget.onTap();
    if (!widget.flashOnTap || widget.active) {
      return;
    }
    setState(() {
      _flashActive = true;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    setState(() {
      _flashActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RCButton(
      onTap: _handleTap,
      active: widget.active || _flashActive,
      enableRepeat: false,
      width: ControlAuxActionPanel.buttonWidth,
      height: ControlAuxActionPanel.buttonHeight,
      padding: EdgeInsets.zero,
      borderRadius: AppDimens.squareButtonRadius,
      textWidget: Text(
        widget.label,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
        style: TextStyle(
          fontSize: 11,
          fontWeight: AppFonts.w600,
          color: widget.active || _flashActive
              ? AppColors.onPrimary
              : const Color(0xFF7DA2CE),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

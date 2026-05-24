import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

class AuxControlButtonViewData {
  const AuxControlButtonViewData({
    required this.label,
    required this.onTap,
    required this.key,
    required this.active,
  });

  final String label;
  final VoidCallback onTap;
  final Key key;
  final bool active;
}

class ControlAuxActionPanel extends StatelessWidget {
  const ControlAuxActionPanel({super.key, required this.auxButtons});

  static const buttonWidth = 92.0;
  static const buttonHeight = 32.0;
  static const itemGap = 8.0;
  static const rowGap = 10.0;
  static const itemsPerRow = 3;

  final List<AuxControlButtonViewData> auxButtons;

  @override
  Widget build(BuildContext context) {
    final rows = <List<AuxControlButtonViewData>>[];
    for (var index = 0; index < auxButtons.length; index += itemsPerRow) {
      rows.add(
        auxButtons.sublist(
          index,
          index + itemsPerRow > auxButtons.length
              ? auxButtons.length
              : index + itemsPerRow,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (
                var itemIndex = 0;
                itemIndex < rows[rowIndex].length;
                itemIndex++
              ) ...[
                if (itemIndex > 0) const SizedBox(width: itemGap),
                _AuxActionButton(
                  key: rows[rowIndex][itemIndex].key,
                  label: rows[rowIndex][itemIndex].label,
                  onTap: rows[rowIndex][itemIndex].onTap,
                  active: rows[rowIndex][itemIndex].active,
                ),
              ],
            ],
          ),
          if (rowIndex < rows.length - 1) const SizedBox(height: rowGap),
        ],
      ],
    );
  }
}

class _AuxActionButton extends StatelessWidget {
  const _AuxActionButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.active,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return RCButton(
      onTap: onTap,
      active: active,
      enableRepeat: false,
      width: ControlAuxActionPanel.buttonWidth,
      height: ControlAuxActionPanel.buttonHeight,
      padding: EdgeInsets.zero,
      borderRadius: AppDimens.squareButtonRadius,
      textWidget: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
        style: TextStyle(
          fontSize: 11,
          fontWeight: AppFonts.w600,
          color: active ? AppColors.onPrimary : const Color(0xFF7DA2CE),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

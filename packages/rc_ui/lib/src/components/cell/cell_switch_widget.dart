import 'package:flutter/material.dart';

import 'cell.dart';

enum SwitchSize { medium, small }

class CellSwitchWidget extends StatelessWidget {
  const CellSwitchWidget({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.icon = Icons.settings,
    this.onTap,
    this.enableHighlight = false,
    this.highlightGradient,
    this.highlightBaseColor,
    this.sizeType = SwitchSize.medium,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enableHighlight;
  final Gradient? highlightGradient;
  final Color? highlightBaseColor;
  final SwitchSize sizeType;

  @override
  Widget build(BuildContext context) {
    return Cell(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      title: title,
      onTap: () => onChanged(!value),
      enableHighlight: enableHighlight,
      highlightGradient: highlightGradient,
      highlightBaseColor: highlightBaseColor,
      widget: _SwitchPill(
        value: value,
        onChanged: onChanged,
        sizeType: sizeType,
      ),
    );
  }
}

class _SwitchPill extends StatelessWidget {
  const _SwitchPill({
    required this.value,
    required this.onChanged,
    required this.sizeType,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final SwitchSize sizeType;

  @override
  Widget build(BuildContext context) {
    double w, h, knob;
    const padding = 2.0; // 增加 2px 边距

    switch (sizeType) {
      case SwitchSize.medium:
        w = 52;
        h = 28;
        knob = 24; // 28 - 2*2
        break;
      case SwitchSize.small:
        w = 44;
        h = 24;
        knob = 20; // 24 - 2*2
        break;
    }

    final width = w;
    final height = h;
    final knobSize = knob;
    final p = padding;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        padding: EdgeInsets.all(p),
        decoration: BoxDecoration(
          color: value ? null : const Color(0xFF465D7A),
          gradient: value
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF0072FF), Color(0xFF00C8FF)],
                )
              : null,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: const Color(0xFF7DA2CE).withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: knobSize,
            height: knobSize,
            decoration: const BoxDecoration(
              color: Color(0xFFEDF5FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x40001024),
                  blurRadius: 4,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

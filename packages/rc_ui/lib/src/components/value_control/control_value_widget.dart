import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';
import 'package:rc_ui/src/elements/button/rc_icon_button.dart';

enum ControlValueStyle { horizontal, vertical }

// const _buttonSize = 32.0;
const _buttonGap = 8.0;
// const _panelWidth = 120.0;
// const _panelHeight = 96.0;

class ControlValueWidget extends StatelessWidget {
  const ControlValueWidget({
    super.key,
    required this.label,
    required this.valueText,
    required this.style,
    this.onMinus,
    this.onPlus,
  });

  final String label;
  final String valueText;
  final ControlValueStyle style;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final panel = _ValuePanel(label: label, valueText: valueText);

    if (style == ControlValueStyle.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RCIconButton(plus: false, onTap: onMinus, size: 32, iconSize: 16),
          const SizedBox(width: _buttonGap),
          panel,
          const SizedBox(width: _buttonGap),
          RCIconButton(plus: true, onTap: onPlus, size: 32, iconSize: 16),
        ],
      );
    }
    return Column(
      children: [
        RCIconButton(plus: true, onTap: onPlus, size: 32, iconSize: 16),
        const SizedBox(height: _buttonGap),
        panel,
        const SizedBox(height: _buttonGap),
        RCIconButton(plus: false, onTap: onMinus, size: 32, iconSize: 16),
      ],
    );
  }
}

class _ValuePanel extends StatelessWidget {
  const _ValuePanel({required this.label, required this.valueText});

  final String label;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0x661B2D4D),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF0072FF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: _textStyle),
          const SizedBox(height: 3),
          Text(valueText, style: _textStyle),
        ],
      ),
    );
  }
}

const _textStyle = TextStyle(
  color: Color(0xFFEDF5FF),
  fontSize: AppFonts.s12,
  height: 1,
);

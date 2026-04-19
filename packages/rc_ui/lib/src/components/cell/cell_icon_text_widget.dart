import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

import 'cell.dart';

class CellIconTextWidget extends StatelessWidget {
  const CellIconTextWidget({
    super.key,
    required this.title,
    required this.valueText,
    this.icon = LucideIcons.chevronRight,
    this.onTap,
    this.enableHighlight = false,
    this.highlightGradient,
    this.highlightBaseColor,
  });

  final String title;
  final String valueText;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enableHighlight;
  final Gradient? highlightGradient;
  final Color? highlightBaseColor;

  @override
  Widget build(BuildContext context) {
    return Cell(
      title: title,
      onTap: onTap,
      enableHighlight: enableHighlight,
      highlightGradient: highlightGradient,
      highlightBaseColor: highlightBaseColor,
      widget: _trailing(),
    );
  }

  Widget _trailing() {
    return Row(
      children: [
        Text(valueText, style: _valueStyle()),
        SizedBox(width: AppDimens.compactCell(8)),
        Icon(
          icon,
          color: const Color(0xFF7DA2CE),
          size: AppDimens.compactIcon(24),
        ),
      ],
    );
  }

  TextStyle _valueStyle() {
    return TextStyle(
      color: const Color(0xFF7DA2CE),
      fontSize: AppFonts.s14,
      fontWeight: AppFonts.w400,
      height: 1,
    );
  }
}

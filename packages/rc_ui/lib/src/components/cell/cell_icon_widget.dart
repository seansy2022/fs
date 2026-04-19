
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

import 'cell.dart';

class CellIconWidget extends StatelessWidget {
  const CellIconWidget({
    super.key,
    required this.title,
    this.icon = LucideIcons.chevronRight,
    this.onTap,
    this.enableHighlight = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enableHighlight;

  @override
  Widget build(BuildContext context) {
    return Cell(
      enableHighlight: enableHighlight,
      title: title,
      onTap: onTap,
      widget: Icon(
        icon,
        color: const Color(0xFF7DA2CE),
        size: AppFonts.s16,
      ),
    );
  }
}

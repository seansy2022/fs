import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rc_ui/rc_ui.dart';

class ControlMappingRowItem extends StatelessWidget {
  const ControlMappingRowItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: AppDimens.item, color: AppColors.outline),
            const SizedBox(width: 12),
            _label(),
            _valueChip(),
          ],
        ),
      ),
    );
  }

  Widget _label() {
    return Expanded(
      child: Text(label, style: AppTextStyles.controlMappingLabel),
    );
  }

  Widget _valueChip() {
    final color = primary ? AppColors.primary : AppColors.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: primary
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Text(value, style: AppTextStyles.controlMappingValue(color)),
          const SizedBox(width: 6),
          Icon(
            LucideIcons.chevronRight,
            size: AppDimens.chevron,
            color: color,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

class SelectOptionToggle extends StatelessWidget {
  const SelectOptionToggle({
    super.key,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            selected
                ? 'assets/icons/select_checked.svg'
                : 'assets/icons/select_unchecked.svg',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.text, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

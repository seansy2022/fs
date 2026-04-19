
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class FailsafeToggleWidget extends StatelessWidget {
  const FailsafeToggleWidget({
    super.key,
    required this.active,
    required this.onChanged,
  });

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 24,
      decoration: BoxDecoration(
        // color: const Color(0x661B2D4D),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          _segment('OFF', !active, () => onChanged(false)),
          _segment('ON', active, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            // borderRadius: BorderRadius.circular(2.5),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x8000C6FF), Color(0x0000C6FF)],
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.onPrimary : const Color(0xFF7DA2CE),
              fontSize: AppFonts.s12,
              // fontWeight: AppFonts.w400,
              // height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

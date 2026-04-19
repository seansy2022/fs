
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class FailsafeCh4Control extends StatelessWidget {
  const FailsafeCh4Control({
    super.key,
    required this.channelId,
    required this.active,
    required this.value,
    required this.onActiveChanged,
    required this.onValueChanged,
  });

  final String channelId;
  final bool active;
  final int value;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<int> onValueChanged;

  bool get _leftSelected => active && value <= 0;
  bool get _middleSelected => !active;
  bool get _rightSelected => active && value > 0;

  void _setLeft() {
    onActiveChanged(true);
    onValueChanged(-100);
  }

  void _setMiddle() {
    onActiveChanged(false);
  }

  void _setRight() {
    onActiveChanged(true);
    onValueChanged(100);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 120,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: Color(0xFF233854))),
      ),
      child: SizedBox(
        // height: 32,
        child: Row(
          children: [
            Text(
              channelId,
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: AppFonts.s14,
                // fontWeight: AppFonts.w700,
              ),
            ),
            const Spacer(),
            _toggle(),
          ],
        ),
      ),
    );
  }

  Widget _toggle() {
    return Container(
      width: 150,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0x661B2D4D),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          _segment(
            label: '-100%',
            selected: _leftSelected,
            onTap: _setLeft,
            isLeft: true,
          ),
          _segment(label: 'OFF', selected: _middleSelected, onTap: _setMiddle),
          _segment(
            label: '100%',
            selected: _rightSelected,
            onTap: _setRight,
            isRight: true,
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isLeft = false,
    bool isRight = false,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? const Radius.circular(2.5) : Radius.zero,
              right: isRight ? const Radius.circular(2.5) : Radius.zero,
            ),
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
              // fontWeight: AppFonts.w700,
              // height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

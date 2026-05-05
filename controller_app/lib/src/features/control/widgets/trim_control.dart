import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

/// Trim adjustment with left/right arrows.
/// Range: -50 to 50, precision 1.
/// Single tap: ±1. Long press (>=500ms): ±5 every 250ms.
class TrimControl extends StatefulWidget {
  const TrimControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<TrimControl> createState() => _TrimControlState();
}

class _TrimControlState extends State<TrimControl> {
  Timer? _longPressTimer;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _adjust(int delta) {
    final next = (widget.value + delta).clamp(-50, 50);
    if (next != widget.value) {
      widget.onChanged(next);
    }
  }

  void _startLongPress(int delta) {
    _longPressTimer?.cancel();
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _adjust(delta * 5);
    });
  }

  void _onPointerDown(int delta) {
    _adjust(delta);
    // 500ms delay before entering rapid mode
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startLongPress(delta);
      }
    });
  }

  void _onPointerUp() {
    _longPressTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowButton(
          icon: Icons.keyboard_arrow_left,
          onTapDown: () => _onPointerDown(-1),
          onTapUp: _onPointerUp,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(
            '${widget.value}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: AppFonts.s16,
              fontWeight: AppFonts.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _ArrowButton(
          icon: Icons.keyboard_arrow_right,
          onTapDown: () => _onPointerDown(1),
          onTapUp: _onPointerUp,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.onTapDown,
    required this.onTapUp,
  });

  final IconData icon;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0x661B2D4D),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF0072FF), width: 0.5),
        ),
        child: Icon(icon, color: AppColors.text, size: 20),
      ),
    );
  }
}

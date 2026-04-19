import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class AlertModelWidget extends StatelessWidget {
  const AlertModelWidget({
    super.key,
    required this.title,
    required this.onCancel,
    required this.onConfirm,
    this.cancelText = '取消',
    this.confirmText = '确定',
  });

  final String title;
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String cancelText = '取消',
    String confirmText = '确定',
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AlertModelWidget(
        title: title,
        cancelText: cancelText,
        confirmText: confirmText,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = _dialogWidth(context);
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: _decoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_titleArea(), _buttonArea(width)],
          ),
        ),
      ),
    );
  }

  double _dialogWidth(BuildContext context) {
    final max = MediaQuery.of(context).size.width - 32;
    return math.min(313, max);
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: const Color(0xFF002149),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xA37DA2CE)),
    );
  }

  Widget _titleArea() {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: AppFonts.s16,
          fontWeight: AppFonts.w500,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buttonArea(double width) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              onPressed: onCancel,
              icon: Text(
                cancelText,
                style: const TextStyle(
                  color: Color(0xFFEDF5FF),
                  fontSize: AppFonts.s14,
                  fontWeight: AppFonts.w400,
                ),
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x661B2D4D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Color(0xFF0072FF), width: 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: IconButton(
              onPressed: onConfirm,
              icon: Text(
                confirmText,
                style: const TextStyle(
                  color: Color(0xFFEDF5FF),
                  fontSize: AppFonts.s14,
                  fontWeight: AppFonts.w400,
                ),
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x661B2D4D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Color(0xFF0072FF), width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

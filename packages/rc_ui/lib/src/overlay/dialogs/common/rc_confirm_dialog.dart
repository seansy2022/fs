import 'package:flutter/material.dart';

import 'rc_dialog_shell.dart';

/// 标准双操作确认弹窗；取消返回 false，确认返回 true。
class RcConfirmDialog extends StatelessWidget {
  const RcConfirmDialog({
    super.key,
    required this.message,
    required this.cancelText,
    required this.confirmText,
    required this.onCancel,
    required this.onConfirm,
  });

  final String message;
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  /// 显示确认弹窗并返回用户选择。
  static Future<bool?> show(
    BuildContext context, {
    required String message,
    required String cancelText,
    required String confirmText,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: const Color(0x99001024),
      builder: (dialogContext) => RcConfirmDialog(
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RcDialogShell(
      width: 313,
      height: 132,
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFEDF5FF), fontSize: 14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 10),
              child: Row(
                children: [
                  _ConfirmActionButton(label: cancelText, onTap: onCancel),
                  const SizedBox(width: 12),
                  _ConfirmActionButton(label: confirmText, onTap: onConfirm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmActionButton extends StatelessWidget {
  const _ConfirmActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 117,
        height: 40,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x661B2D4D),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF0072FF)),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFEDF5FF), fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

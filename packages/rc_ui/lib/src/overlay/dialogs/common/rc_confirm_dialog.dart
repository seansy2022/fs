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
    this.icon,
  });

  final String message;
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final Widget? icon;

  /// 显示确认弹窗并返回用户选择。
  static Future<bool?> show(
    BuildContext context, {
    required String message,
    required String cancelText,
    required String confirmText,
    Widget? icon,
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
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RcDialogShell(
      width: 313,
      height: icon == null ? 132 : 200,
      child: Column(
        children: [
          _buildMessageArea(),
          Expanded(child: _buildButtonArea()),
        ],
      ),
    );
  }

  /// 无图标时保留原布局；传入图标时按状态弹窗结构展示图标和正文。
  Widget _buildMessageArea() {
    if (icon == null) {
      return SizedBox(height: 72, child: Center(child: _buildMessage()));
    }
    return SizedBox(
      height: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 60, child: Center(child: icon)),
          const SizedBox(height: 8),
          _buildMessage(),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFFEDF5FF), fontSize: 14),
    );
  }

  Widget _buildButtonArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _ConfirmActionButton(label: cancelText, onTap: onCancel),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ConfirmActionButton(label: confirmText, onTap: onConfirm),
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

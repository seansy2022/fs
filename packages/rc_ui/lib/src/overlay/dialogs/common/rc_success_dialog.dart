import 'dart:async';

import 'package:flutter/material.dart';

import 'rc_dialog_shell.dart';

/// 标准保存成功提示，可在指定时间后自动关闭。
class RcSuccessDialog extends StatelessWidget {
  const RcSuccessDialog({super.key, required this.message});

  final String message;

  /// 显示成功提示，并在 duration 后关闭弹窗。
  static Future<void> show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 900),
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x99001024),
      builder: (dialogContext) =>
          _AutoDismissSuccessDialog(message: message, duration: duration),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RcDialogShell(
      height: 126,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0x2967E600),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF67E600), size: 25),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: Color(0xFFEDF5FF), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _AutoDismissSuccessDialog extends StatefulWidget {
  const _AutoDismissSuccessDialog({
    required this.message,
    required this.duration,
  });

  final String message;
  final Duration duration;

  @override
  State<_AutoDismissSuccessDialog> createState() =>
      _AutoDismissSuccessDialogState();
}

class _AutoDismissSuccessDialogState extends State<_AutoDismissSuccessDialog> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  /// 仅在成功提示仍显示时关闭当前弹窗路由。
  void _dismiss() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RcSuccessDialog(message: widget.message);
  }
}

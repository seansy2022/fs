import 'dart:async';

import 'package:flutter/material.dart';

import '../dialogs/common/rc_dialog_shell.dart';

/// 不阻断当前页面操作的短时提示，适用于输入校验等轻量反馈。
class RcToast {
  RcToast._();

  static OverlayEntry? _entry;
  static Timer? _dismissTimer;

  /// 显示 Toast；新的提示会替换仍在显示的旧提示。
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 1600),
  }) {
    _dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: Positioned.fill(
          child: RcDialogShell(
            width: 280,
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFEDF5FF),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, _dismiss);
  }

  /// 清理当前提示及计时器，避免多条提示重叠。
  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _entry?.remove();
    _entry = null;
  }
}

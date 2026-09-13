import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../core/localization/app_localizations.dart';
import 'receiver_safety_confirmation.dart';

/// 删除已配对设备：连接中的设备先确认并断开，未连接设备直接删除。
Future<bool> deletePairedDeviceWithFeedback(
  BuildContext context, {
  required bool isConnected,
  required Future<bool> Function() disconnect,
  required Future<void> Function() remove,
}) async {
  if (isConnected) {
    final confirmed = await showReceiverSafetyConfirmation(
      context,
      message: AppText.tr('操作会导致失控，请确认安全！\n此设备正在使用，确定删除吗？'),
    );
    if (!confirmed) {
      return false;
    }
    try {
      final disconnected = await disconnect();
      if (!disconnected) {
        if (!context.mounted) {
          return false;
        }
        await _showDeleteFailure(context, AppText.tr('当前连接接收机断开失败，请重试。'));
        return false;
      }
    } catch (_) {
      if (!context.mounted) {
        return false;
      }
      await _showDeleteFailure(context, AppText.tr('当前连接接收机断开失败，请重试。'));
      return false;
    }
  }

  try {
    await remove();
    return true;
  } catch (_) {
    if (!context.mounted) {
      return false;
    }
    await _showDeleteFailure(context, AppText.tr('删除历史设备失败，请重试。'));
    return false;
  }
}

/// 页面仍有效时显示删除失败反馈，避免异步返回后访问失效上下文。
Future<void> _showDeleteFailure(BuildContext context, String message) async {
  if (!context.mounted) {
    return;
  }
  await AlertIconWidget.show(
    context,
    title: AppText.tr('删除失败'),
    message: message,
    confirmText: AppText.tr('知道了'),
  );
}

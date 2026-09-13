import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../core/localization/app_localizations.dart';

const _deleteWarningSvg = '''
<svg viewBox="0 0 1088 1024" xmlns="http://www.w3.org/2000/svg">
  <path d="M555.072 832.576v83.2h-83.2v-83.2h83.2zM475.456 128h76.8v576h-76.8z" fill="#000000" fill-opacity=".9"/>
</svg>
''';

/// 删除已配对设备：连接中的设备先确认并断开，未连接设备直接删除。
Future<bool> deletePairedDeviceWithFeedback(
  BuildContext context, {
  required bool isConnected,
  required Future<bool> Function() disconnect,
  required Future<void> Function() remove,
}) async {
  if (isConnected) {
    final confirmed = await RcConfirmDialog.show(
      context,
      message: AppText.tr('操作会导致失控，请确认安全！\n此设备正在使用，确定删除吗？'),
      cancelText: AppText.tr('否'),
      confirmText: AppText.tr('是'),
      icon: const _DeleteWarningIcon(),
    );
    if (confirmed != true) {
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

class _DeleteWarningIcon extends StatelessWidget {
  const _DeleteWarningIcon();

  @override
  Widget build(BuildContext context) {
    // 使用 40×40 浅黄色圆形底，中间保留需求指定 SVG 的黑色感叹号。
    return SizedBox.square(
      key: const ValueKey<String>('paired-device-delete-warning-icon'),
      dimension: 40,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFFFE082),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.string(_deleteWarningSvg, width: 32, height: 32),
        ),
      ),
    );
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

import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../../core/localization/app_localizations.dart';

/// 显示校准页退出确认框，返回 true 表示用户确认保存。
Future<bool> showGyroCalibrationExitDialog(BuildContext context) async {
  final shouldSave = await RcConfirmDialog.show(
    context,
    message: AppText.tr('对应角度已被修改，是否保存'),
    cancelText: AppText.tr('取消'),
    confirmText: AppText.tr('确定'),
    barrierDismissible: false,
  );
  return shouldSave ?? false;
}

/// 显示保存成功提示，短暂展示后自动关闭。
Future<void> showGyroCalibrationSaveSuccessDialog(BuildContext context) {
  return RcSuccessDialog.show(
    context,
    message: AppText.tr('保存成功'),
    duration: const Duration(milliseconds: 900),
  );
}

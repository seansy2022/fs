import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../core/localization/app_localizations.dart';

const _warningSvg = '''
<svg viewBox="0 0 1088 1024" xmlns="http://www.w3.org/2000/svg">
  <path d="M555.072 832.576v83.2h-83.2v-83.2h83.2zM475.456 128h76.8v576h-76.8z" fill="#000000" fill-opacity=".9"/>
</svg>
''';

/// 显示统一的接收机安全确认弹窗。
Future<bool> showReceiverSafetyConfirmation(
  BuildContext context, {
  required String message,
}) async {
  final confirmed = await RcConfirmDialog.show(
    context,
    message: message,
    cancelText: AppText.tr('否'),
    confirmText: AppText.tr('是'),
    icon: const ReceiverSafetyWarningIcon(),
  );
  return confirmed == true;
}

/// 当前已连接其他接收机时，连接新设备前要求用户确认。
Future<bool> confirmReceiverSwitchIfNeeded(
  BuildContext context, {
  required String? connectedRemoteId,
  required String targetRemoteId,
}) {
  if (connectedRemoteId == null || connectedRemoteId == targetRemoteId) {
    return Future<bool>.value(true);
  }
  return showReceiverSafetyConfirmation(
    context,
    message: AppText.tr('操作会导致失控，请确认安全！\n确定断开当前设备，连接新设备吗？'),
  );
}

class ReceiverSafetyWarningIcon extends StatelessWidget {
  const ReceiverSafetyWarningIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const ValueKey<String>('receiver-safety-warning-icon'),
      dimension: 40,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFFFE082),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.string(_warningSvg, width: 32, height: 32),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../provider/global_reconnect_provider.dart';
import 'reconnect_overlay_view.dart';

class GlobalReconnectOverlay extends ConsumerWidget {
  const GlobalReconnectOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(globalReconnectControllerProvider);
    if (!state.active || state.startedAt == null) {
      return const SizedBox.shrink();
    }
    return ReconnectOverlayView(
      title: AppText.tr('正在重连'),
      deviceName: state.deviceName ?? AppText.tr('蓝牙设备'),
      startedAt: state.startedAt!,
      actionLabel: AppText.tr('取消'),
      onAction: () {
        ref.read(globalReconnectControllerProvider.notifier).cancel();
      },
    );
  }
}

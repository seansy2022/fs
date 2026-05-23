import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../provider/bluetooth_domain_provider.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../widgets/bluetooth_connect_feedback.dart';

class DeviceListPage extends ConsumerWidget {
  const DeviceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bluetoothState = ref.watch(bluetoothDomainControllerProvider);
    final devices = bluetoothState.pairedDevices;
    final bluetoothController = ref.read(
      bluetoothDomainControllerProvider.notifier,
    );
    return AppPageScaffold(
      title: '\u5df2\u914d\u5bf9\u8bbe\u5907',
      onBack: () => Navigator.of(context).pop(),
      body: AlertBlueWidget(
        title: '\u5df2\u914d\u5bf9\u8bbe\u5907\u5217\u8868',
        items: devices
            .map(
              (device) => AlertBlueItem(
                title: device.name,
                status: device.isConnected
                    ? '\u5df2\u8fde\u63a5'
                    : '\u672a\u8fde\u63a5',
                statusColor: device.isConnected
                    ? const Color(0xFF00C6FF)
                    : Colors.white.withValues(alpha: 0.65),
              ),
            )
            .toList(growable: false),
        emptyText: '\u6682\u65e0\u5386\u53f2\u8bbe\u5907',
        onTap: (item) async {
          final target = devices.firstWhere((d) => d.name == item.title);
          if (target.isConnected) {
            return;
          }
          await showBluetoothConnectFeedback(
            context,
            connect: () => bluetoothController.connect(target.remoteId),
          );
        },
        onDelete: (item) async {
          final target = devices.firstWhere((d) => d.name == item.title);
          final confirmed = await AlertIconWidget.show(
            context,
            title: '\u5220\u9664\u8bbe\u5907',
            message:
                '\u786e\u5b9a\u5220\u9664\u8bbe\u5907 ${target.name} \u5417\uff1f',
            cancelText: '\u53d6\u6d88',
            confirmText: '\u786e\u5b9a',
          );
          if (confirmed != true) {
            return;
          }
          try {
            if (target.isConnected) {
              await bluetoothController.disconnect();
            }
            await bluetoothController.removeRememberedDevice(target.remoteId);
          } catch (_) {
            if (!context.mounted) {
              return;
            }
            await AlertIconWidget.show(
              context,
              title: '\u5220\u9664\u5931\u8d25',
              message:
                  '\u5220\u9664\u5386\u53f2\u8bbe\u5907\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5\u3002',
              confirmText: '\u77e5\u9053\u4e86',
            );
          }
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}

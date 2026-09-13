import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../provider/bluetooth_domain_provider.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../widgets/bluetooth_connect_feedback.dart';
import '../widgets/paired_device_delete_flow.dart';

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
            cancelPendingConnection:
                bluetoothController.cancelPendingConnection,
          );
        },
        onDelete: (item) async {
          final target = devices.firstWhere((d) => d.name == item.title);
          final currentState = ref.read(bluetoothDomainControllerProvider);
          final isConnected =
              target.isConnected ||
              currentState.connectedDevice?.remoteId == target.remoteId;
          await deletePairedDeviceWithFeedback(
            context,
            isConnected: isConnected,
            disconnect: bluetoothController.disconnect,
            remove: () =>
                bluetoothController.removeRememberedDevice(target.remoteId),
          );
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}

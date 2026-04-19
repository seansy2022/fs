import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../core/providers.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

class DeviceListPage extends ConsumerStatefulWidget {
  const DeviceListPage({super.key});

  @override
  ConsumerState<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends ConsumerState<DeviceListPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(receiverRepositoryProvider).startScan());
    });
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(mergedReceiverDevicesProvider);
    return AppPageScaffold(
      title: '已配对设备',
      onBack: () => Navigator.of(context).pop(),
      onRefresh: () {
        unawaited(ref.read(receiverRepositoryProvider).startScan());
      },
      body: Column(
        children: [
          const Panel(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '在线设备优先展示，离线设备会保留在列表中供后续重新连接。',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: devices.isEmpty
                ? const Panel(
                    child: Center(
                      child: Text(
                        '暂无已识别设备',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: AppFonts.s14,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: devices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return Panel(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: AppFonts.s16,
                                      fontWeight: AppFonts.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    device.remoteId,
                                    style: const TextStyle(
                                      color: AppColors.textDim,
                                      fontSize: AppFonts.s12,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _statusLabel(device),
                                    style: TextStyle(
                                      color: device.connected
                                          ? AppColors.primaryBright
                                          : device.rssi > -120
                                          ? AppColors.tertiary
                                          : AppColors.textDim,
                                      fontSize: AppFonts.s12,
                                      fontWeight: AppFonts.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                PrimaryButton(
                                  text: device.connected ? '已连接' : '连接',
                                  width: 88,
                                  enabled: !_busy && device.rssi > -120,
                                  onTap: device.connected
                                      ? null
                                      : () => _connect(device),
                                ),
                                const SizedBox(height: 8),
                                if (device.rssi <= -120)
                                  PrimaryButton(
                                    text: '移除',
                                    width: 88,
                                    type: PrimaryButtonType.normal,
                                    onTap: () => ref
                                        .read(
                                          rememberedDevicesProvider.notifier,
                                        )
                                        .removeDevice(device.remoteId),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ReceiverScanDevice device) {
    if (device.connected) {
      return '正在使用';
    }
    if (device.rssi > -120) {
      return '在线可连接  ${device.rssi} dBm';
    }
    return '离线';
  }

  Future<void> _connect(ReceiverScanDevice device) async {
    setState(() => _busy = true);
    try {
      await ref.read(receiverRepositoryProvider).connect(device.remoteId);
      await ref.read(rememberedDevicesProvider.notifier).rememberDevice(device);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已连接 ${device.name}')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('连接失败: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

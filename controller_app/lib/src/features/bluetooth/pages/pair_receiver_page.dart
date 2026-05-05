import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../core/providers.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

class PairReceiverPage extends ConsumerStatefulWidget {
  const PairReceiverPage({super.key});

  @override
  ConsumerState<PairReceiverPage> createState() => _PairReceiverPageState();
}

class _PairReceiverPageState extends ConsumerState<PairReceiverPage> {
  bool _scanning = true;
  bool _autoSearchDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(receiverRepositoryProvider).startScan());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onDeviceFound(ReceiverScanDevice device) async {
    if (!mounted) return;
    try {
      await ref.read(receiverRepositoryProvider).connect(device.remoteId);
      await ref.read(rememberedDevicesProvider.notifier).rememberDevice(device);
      if (!mounted) return;
      _showPairSuccessDialog();
    } catch (_) {
      // 配对失败静默继续扫描
    }
  }

  void _showPairSuccessDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xCC000000),
      builder: (dialogContext) {
        // 3S后自动关闭
        Future<void>.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
          if (mounted) {
            Navigator.of(context).pop(); // 返回开始页
          }
        });
        return const BlueConnectSuccessLoading(text: '配对成功!');
      },
    );
  }

  void _showPairedDeviceDialog(ReceiverScanDevice device) {
    if (!mounted || _autoSearchDismissed) return;
    AlertIconWidget.show(
      context,
      title: '发现已配对设备',
      message: '检测到 ${device.name}，是否连接？',
      cancelText: '不再提示',
      confirmText: '是',
    ).then((result) {
      if (!mounted) return;
      if (result == true) {
        // 连接此接收机并返回开始页
        unawaited(() async {
          try {
            await ref.read(receiverRepositoryProvider).connect(device.remoteId);
            if (mounted) Navigator.of(context).pop();
          } catch (_) {}
        }());
      } else {
        // 不再提示
        setState(() => _autoSearchDismissed = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref
        .watch(receiverDevicesProvider)
        .maybeWhen(
          data: (value) => value
              .where((device) => device.rssi > -120)
              .toList(growable: false),
          orElse: () => const <ReceiverScanDevice>[],
        );

    final remembered = ref.watch(rememberedDevicesProvider);
    final rememberedIds = remembered.map((r) => r.remoteId).toSet();

    // Separate new devices from remembered ones
    final newDevices = devices
        .where((d) => !rememberedIds.contains(d.remoteId))
        .toList(growable: false);
    final onlineRemembered = devices
        .where((d) => rememberedIds.contains(d.remoteId))
        .toList(growable: false);

    // Auto-pair: connect to first new device
    if (_scanning && newDevices.isNotEmpty) {
      final firstNew = newDevices.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scanning) {
          setState(() => _scanning = false);
          unawaited(_onDeviceFound(firstNew));
        }
      });
    }

    // Check for online remembered devices (dialog1)
    if (_scanning && onlineRemembered.isNotEmpty && !_autoSearchDismissed) {
      final firstRemembered = onlineRemembered.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPairedDeviceDialog(firstRemembered);
      });
    }

    return AppPageScaffold(
      title: '去配对',
      onBack: () => Navigator.of(context).pop(),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Panel(
              child: Stack(
                children: [
                  const Positioned.fill(child: BluetoothSearchingView()),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Text(
                      _scanning
                          ? '正在搜索接收机...'
                          : '正在配对中，请稍候...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            flex: 6,
            child: devices.isEmpty
                ? const Panel(
                    child: Center(
                      child: Text(
                        '请保持接收机处于蓝牙模式（LED 快闪）',
                        textAlign: TextAlign.center,
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
                      final isNew = !rememberedIds.contains(device.remoteId);
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
                                    isNew ? '新设备' : '已配对',
                                    style: TextStyle(
                                      color: isNew
                                          ? AppColors.primaryBright
                                          : AppColors.textDim,
                                      fontSize: AppFonts.s12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${device.rssi} dBm',
                              style: const TextStyle(
                                color: AppColors.textDim,
                                fontSize: AppFonts.s12,
                              ),
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
}

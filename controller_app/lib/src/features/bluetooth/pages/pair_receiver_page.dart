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
    final devices = ref
        .watch(receiverDevicesProvider)
        .maybeWhen(
          data: (value) => value
              .where((device) => device.rssi > -120)
              .toList(growable: false),
          orElse: () => const <ReceiverScanDevice>[],
        );

    return AppPageScaffold(
      title: '去配对',
      onBack: () => Navigator.of(context).pop(),
      onRefresh: () {
        unawaited(ref.read(receiverRepositoryProvider).startScan());
      },
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
                      '请保持接收机处于蓝牙模式（LED 快闪）后再进行连接。',
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
                        '正在搜索附近的蓝牙接收机...',
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
                                    '信号 ${device.rssi} dBm',
                                    style: const TextStyle(
                                      color: AppColors.textDim,
                                      fontSize: AppFonts.s12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            PrimaryButton(
                              text: '连接',
                              width: 88,
                              enabled: !_busy,
                              onTap: () => _pair(device),
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

  Future<void> _pair(ReceiverScanDevice device) async {
    setState(() => _busy = true);
    try {
      await ref.read(receiverRepositoryProvider).connect(device.remoteId);
      await ref.read(rememberedDevicesProvider.notifier).rememberDevice(device);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('配对完成：${device.name}')));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('配对失败: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

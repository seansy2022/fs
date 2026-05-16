import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../core/providers.dart';
import '../../../provider/bluetooth_domain_provider.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../widgets/bluetooth_connect_feedback.dart';

class PairReceiverPage extends ConsumerStatefulWidget {
  const PairReceiverPage({super.key});

  @override
  ConsumerState<PairReceiverPage> createState() => _PairReceiverPageState();
}

class _PairReceiverPageState extends ConsumerState<PairReceiverPage> {
  bool _sessionActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_sessionActive || !mounted) {
        return;
      }
      await _ensureListScanWithFeedback();
    });
  }

  @override
  void dispose() {
    _sessionActive = false;
    unawaited(
      ref
          .read(bluetoothDomainControllerProvider.notifier)
          .stopScan(sessionOwner: BluetoothScanOwner.listPage),
    );
    super.dispose();
  }

  Future<void> _ensureListScanWithFeedback() async {
    if (!_sessionActive || !mounted) {
      return;
    }
    final started = await ref
        .read(bluetoothDomainControllerProvider.notifier)
        .startListScanSession();
    if (!_sessionActive || !mounted) {
      return;
    }
    if (!started) {
      await AlertIconWidget.show(
        context,
        title: '\u626b\u63cf\u5931\u8d25',
        message:
            '\u65e0\u6cd5\u542f\u52a8\u84dd\u7259\u626b\u63cf\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5\u3002',
        confirmText: '\u77e5\u9053\u4e86',
      );
    }
  }

  Future<void> _refreshScanWithFeedback() async {
    if (!_sessionActive || !mounted) {
      return;
    }
    final refreshed = await ref
        .read(bluetoothDomainControllerProvider.notifier)
        .refreshScan();
    if (!_sessionActive || !mounted) {
      return;
    }
    if (!refreshed) {
      await AlertIconWidget.show(
        context,
        title: '\u5237\u65b0\u5931\u8d25',
        message:
            '\u84dd\u7259\u626b\u63cf\u5237\u65b0\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5\u3002',
        confirmText: '\u77e5\u9053\u4e86',
      );
    }
  }

  Future<void> _connect(ReceiverDeviceView device) async {
    if (!_sessionActive || !mounted) {
      return;
    }
    final result = await showBluetoothConnectFeedback(
      context,
      connect: () => ref
          .read(bluetoothDomainControllerProvider.notifier)
          .connect(device.remoteId),
    );
    if (!_sessionActive || !mounted) {
      return;
    }
    if (result == BluetoothConnectFeedbackResult.success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(bluetoothDomainControllerProvider);
    final devices = scanState.discoveredDevices;
    return AppPageScaffold(
      title: '\u626b\u63cf\u84dd\u7259\u5217\u8868',
      onBack: () => Navigator.of(context).pop(),
      body: AlertBlueWidget(
        title: '\u626b\u63cf\u84dd\u7259\u5217\u8868',
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
        headerLoading: scanState.isScanning || scanState.isWorking,
        onRefresh: scanState.isWorking ? null : _refreshScanWithFeedback,
        emptyText: '\u6682\u65e0\u53ef\u7528\u84dd\u7259\u8bbe\u5907',
        onTap: (item) async {
          final target = devices.firstWhere((d) => d.name == item.title);
          if (target.isConnected) {
            return;
          }
          await _connect(target);
        },
        onDelete: null,
        onClose: () {
          _sessionActive = false;
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

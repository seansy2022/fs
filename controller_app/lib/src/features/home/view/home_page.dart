import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers.dart';
import '../../../provider/bluetooth_domain_provider.dart';
import '../../../provider/device_status_provider.dart';
import '../../../provider/effective_bluetooth_provider.dart';
import '../../bluetooth/widgets/bluetooth_connect_feedback.dart';
import 'home_reconnect_dialog.dart';

const _blueSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40" fill="none">
  <path stroke="rgba(103, 230, 0, 1)" stroke-width="3.333333333333334" stroke-linejoin="round" stroke-linecap="round" d="M12 11.75L29 27.5001L20.5 35.0001L20.5 5L29 12.5L12 28.2501"></path>
</svg>
''';

const _unBlueSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40" fill="none">
  <path stroke="rgba(125, 162, 206, 1)" stroke-width="3.333333333333334" stroke-linejoin="round" stroke-linecap="round" d="M12 11.75L29 27.5001L20.5 35.0001L20.5 5L29 12.5L12 28.2501"></path>
</svg>
''';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _historyLoadDelay = Duration(milliseconds: 120);
  static const _autoReconnectDuration = Duration(seconds: 5);
  DateTime? _lastHandledPromptAt;
  DateTime? _reconnectStartedAt;
  String? _lastReconnectFailureMessage;
  bool _handlingPrompt = false;
  bool _autoReconnectActive = false;
  bool _autoReconnectAttempted = false;
  bool _autoReconnectCancelled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(_historyLoadDelay, _startAutoReconnectIfNeeded);
    });
  }

  Future<void> _startAutoReconnectIfNeeded() async {
    final bluetoothState = ref.read(bluetoothDomainControllerProvider);
    final remembered = ref.read(rememberedDevicesProvider);
    if (_autoReconnectAttempted ||
        _autoReconnectActive ||
        bluetoothState.hasBootstrappedHome ||
        remembered.isEmpty) {
      return;
    }
    setState(() {
      _autoReconnectAttempted = true;
      _autoReconnectActive = true;
      _autoReconnectCancelled = false;
      _reconnectStartedAt = DateTime.now();
    });
    final connected = await ref
        .read(bluetoothDomainControllerProvider.notifier)
        .autoReconnectLastDevice(timeout: _autoReconnectDuration);
    if (!mounted) {
      return;
    }
    setState(() {
      _autoReconnectActive = false;
      _reconnectStartedAt = null;
    });
    if (connected || _autoReconnectCancelled) {
      return;
    }
    final failure = _resolveReconnectFailure(
      ref.read(bluetoothDomainControllerProvider).errorMessage,
    );
    if (failure == null) {
      return;
    }
    _showReconnectFailure(failure);
  }

  /// 关闭配对提示并取消本次首页自动重连，避免连接在后台继续完成。
  void _cancelAutoReconnect() {
    if (!_autoReconnectActive) {
      return;
    }
    setState(() {
      _autoReconnectCancelled = true;
      _autoReconnectActive = false;
      _reconnectStartedAt = null;
    });
    unawaited(
      ref
          .read(bluetoothDomainControllerProvider.notifier)
          .cancelPendingAutoReconnect(),
    );
  }

  _ReconnectFailure? _resolveReconnectFailure(String? errorMessage) {
    if (errorMessage == null || errorMessage.isEmpty) {
      return null;
    }
    return _ReconnectFailure(
      title: AppText.tr('连接失败'),
      message: errorMessage,
      confirmText: AppText.tr('知道了'),
    );
  }

  void _showReconnectFailure(_ReconnectFailure failure) {
    if (!mounted || _lastReconnectFailureMessage == failure.message) {
      return;
    }
    _lastReconnectFailureMessage = failure.message;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await AlertIconWidget.show(
        context,
        title: failure.title,
        message: failure.message,
        confirmText: failure.confirmText,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(rememberedDevicesProvider, (_, next) {
      if (next.isNotEmpty) {
        _startAutoReconnectIfNeeded();
      }
    });
    final bluetoothState = ref.watch(bluetoothDomainControllerProvider);
    ref.listen<BluetoothDomainState>(bluetoothDomainControllerProvider, (
      _,
      next,
    ) {
      final promptAt = next.lastBootstrapPromptAt;
      if (_handlingPrompt ||
          next.pendingBootstrapPrompt == BluetoothBootstrapPrompt.none ||
          promptAt == null ||
          promptAt == _lastHandledPromptAt) {
        return;
      }
      _lastHandledPromptAt = promptAt;
      _handlingPrompt = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showBootstrapPrompt(next.pendingBootstrapPrompt);
        _handlingPrompt = false;
      });
    });

    final connectionState = ref.watch(effectiveReceiverConnectionProvider);
    final connectedRssi = ref.watch(effectiveConnectedRssiProvider);
    final connectedDevice = bluetoothState.connectedDevice;
    final connected = connectionState == ReceiverConnectionState.connected;
    final batteryStatus = ref.watch(receiverBatteryStatusProvider);
    final batteryLevel = batteryStatus?.displayPercent;
    final rssi = connected ? (connectedRssi ?? connectedDevice?.rssi) : null;
    final deviceName = connectedDevice?.name ?? '--';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/src/assets/image_enhanced.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0D1B2A),
                      Color(0xFF1B263B),
                      Color(0xFF0A1320),
                    ],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  child: RCButton(
                    iconWidget: SvgPicture.string(
                      connected ? _blueSvg : _unBlueSvg,
                      width: 20,
                      height: 20,
                    ),
                    textWidget: Text(
                      deviceName,
                      style: TextStyle(
                        color: connected
                            ? AppColors.onPrimary
                            : AppColors.textDim,
                        fontSize: AppFonts.s14,
                      ),
                    ),
                    active: connected,
                    isRounded: true,
                    onTap: () => _onBluetoothTap(context),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 112,
                            height: 120,
                            child: HomeMetric(
                              label: AppText.tr('RX电量'),
                              value: batteryLevel != null
                                  ? '$batteryLevel'
                                  : '--',
                              unit: batteryLevel != null ? '%' : '',
                              emphasize: connected,
                            ),
                          ),
                          const SizedBox(width: 64),
                          SizedBox(
                            width: 112,
                            height: 120,
                            child: HomeMetric(
                              label: AppText.tr('信号强度'),
                              value: rssi != null ? '$rssi' : '--',
                              unit: rssi != null ? 'dBm' : '',
                              emphasize: connected,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HomeActionButton(
                            text: AppText.tr('设置'),
                            width: 174,
                            height: 44,
                            backgroundColor: const Color.fromRGBO(
                              27,
                              45,
                              77,
                              1,
                            ),
                            icon: SvgPicture.asset(
                              'assets/icons/home_settings.svg',
                              width: 15,
                              height: 15,
                            ),
                            onTap: () async {
                              await ref
                                  .read(
                                    bluetoothDomainControllerProvider.notifier,
                                  )
                                  .ensureScanStopped();
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.settings);
                            },
                          ),
                          const SizedBox(width: 20),
                          _HomeActionButton(
                            text: AppText.tr('开始'),
                            width: 160,
                            height: 44,
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primaryBright,
                                AppColors.primary,
                              ],
                            ),
                            textColor: AppColors.bg,
                            icon: SvgPicture.asset(
                              'assets/icons/home_start.svg',
                              width: 20,
                              height: 17,
                            ),
                            onTap: () async {
                              await ref
                                  .read(
                                    bluetoothDomainControllerProvider.notifier,
                                  )
                                  .ensureScanStopped();
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.control);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_reconnectStartedAt != null)
            _HomeReconnectOverlay(onClose: _cancelAutoReconnect),
        ],
      ),
    );
  }

  Future<void> _showBootstrapPrompt(BluetoothBootstrapPrompt prompt) async {
    if (!mounted) {
      return;
    }
    final bluetoothController = ref.read(
      bluetoothDomainControllerProvider.notifier,
    );
    if (prompt == BluetoothBootstrapPrompt.permissionRequired) {
      final confirm = await AlertIconWidget.show(
        context,
        title: '\u84dd\u7259\u6743\u9650\u672a\u5f00\u542f',
        message:
            '\u8bf7\u5f00\u542f\u84dd\u7259\u6743\u9650\u540e\u518d\u7ee7\u7eed\u3002',
        cancelText: '\u53d6\u6d88',
        confirmText: '\u53bb\u5f00\u542f',
      );
      await bluetoothController.clearBootstrapPrompt();
      if (confirm == true) {
        await bluetoothController.requestPermissionOrOpenSettings();
        await bluetoothController.retryHomeBluetooth();
      }
      return;
    }
    if (prompt == BluetoothBootstrapPrompt.bluetoothOff) {
      final confirm = await AlertIconWidget.show(
        context,
        title: '\u84dd\u7259\u672a\u5f00\u542f',
        message:
            '\u9700\u8981\u6253\u5f00\u84dd\u7259\u624d\u80fd\u8fde\u63a5\u63a5\u6536\u673a\uff0c\u662f\u5426\u524d\u5f80\u6253\u5f00\u84dd\u7259\uff1f',
        cancelText: '\u5426',
        confirmText: '\u662f',
      );
      await bluetoothController.clearBootstrapPrompt();
      if (confirm == true) {
        await bluetoothController.openBluetoothSettings();
        await bluetoothController.retryHomeBluetooth();
      }
    }
  }

  Future<void> _onBluetoothTap(BuildContext context) async {
    final bluetoothController = ref.read(
      bluetoothDomainControllerProvider.notifier,
    );
    final bluetoothState = ref.read(bluetoothDomainControllerProvider);
    var availability = bluetoothState.availability;
    if (availability == BluetoothAvailability.unknown) {
      availability = await bluetoothController.ensureReadyForEntry();
    }
    if (!context.mounted) {
      return;
    }
    if (availability == BluetoothAvailability.bluetoothOff) {
      await _showBootstrapPrompt(BluetoothBootstrapPrompt.bluetoothOff);
      return;
    }
    if (availability == BluetoothAvailability.permissionRequired) {
      await _showBootstrapPrompt(BluetoothBootstrapPrompt.permissionRequired);
      return;
    }
    if (availability == BluetoothAvailability.unsupported) {
      await AlertIconWidget.show(
        context,
        title: '\u84dd\u7259\u4e0d\u53ef\u7528',
        message:
            '\u5f53\u524d\u8bbe\u5907\u4e0d\u652f\u6301\u84dd\u7259\u8fde\u63a5\u3002',
        confirmText: '\u77e5\u9053\u4e86',
      );
      return;
    }
    if (availability == BluetoothAvailability.unknown) {
      await AlertIconWidget.show(
        context,
        title: '\u72b6\u6001\u83b7\u53d6\u4e2d',
        message:
            '\u6b63\u5728\u83b7\u53d6\u84dd\u7259\u72b6\u6001\uff0c\u8bf7\u7a0d\u540e\u518d\u8bd5\u3002',
        confirmText: '\u77e5\u9053\u4e86',
      );
      return;
    }

    if (!context.mounted) {
      return;
    }
    final option = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xCC000000),
      builder: (_) => const _PairedDevicesDialogContent(),
    );
    if (!context.mounted) {
      return;
    }
    if (option == 'scan_pairing') {
      await _openScanPairingEntry(context);
    }
  }

  Future<void> _openScanPairingEntry(BuildContext context) async {
    if (ref.read(effectiveReceiverConnectionProvider) ==
        ReceiverConnectionState.connected) {
      final confirmed = await AlertIconWidget.show(
        context,
        title: AppText.tr('提示'),
        message: AppText.tr('确定放弃当前连接接收机去配对其它接收机？'),
        cancelText: AppText.tr('取消'),
        confirmText: AppText.tr('确定'),
      );
      if (confirmed != true || !context.mounted) {
        return;
      }
      final disconnected = await ref
          .read(bluetoothDomainControllerProvider.notifier)
          .disconnect();
      if (!disconnected) {
        if (!context.mounted) {
          return;
        }
        await AlertIconWidget.show(
          context,
          title: AppText.tr('断开失败'),
          message: AppText.tr('当前连接接收机断开失败，请重试。'),
          confirmText: AppText.tr('知道了'),
        );
        return;
      }
    }
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xCC000000),
      builder: (_) => const _ScanDevicesDialogContent(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _HomeReconnectOverlay extends StatelessWidget {
  const _HomeReconnectOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x66000000),
        child: Center(child: HomeReconnectDialog(onClose: onClose)),
      ),
    );
  }
}

class _ReconnectFailure {
  const _ReconnectFailure({
    required this.title,
    required this.message,
    required this.confirmText,
  });

  final String title;
  final String message;
  final String confirmText;
}

class _PairedDevicesDialogContent extends ConsumerWidget {
  const _PairedDevicesDialogContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bluetoothState = ref.watch(bluetoothDomainControllerProvider);
    final devices = bluetoothState.pairedDevices;
    final bluetoothController = ref.read(
      bluetoothDomainControllerProvider.notifier,
    );
    final itemMap = <AlertBlueItem, ReceiverDeviceView>{};
    final items = devices
        .map((device) {
          final item = AlertBlueItem(
            title: device.name,
            status: device.isConnected ? context.tr('已连接') : context.tr('未连接'),
            statusColor: device.isConnected
                ? const Color(0xFF00C6FF)
                : Colors.white.withValues(alpha: 0.65),
          );
          itemMap[item] = device;
          return item;
        })
        .toList(growable: false);

    return AlertBlueWidget(
      title: context.tr('已配对设备列表'),
      items: items,
      emptyText: context.tr('暂无历史设备'),
      onTap: (item) async {
        final target = itemMap[item];
        if (target == null) {
          return;
        }
        if (target.isConnected) {
          return;
        }
        final result = await showBluetoothConnectFeedback(
          context,
          connect: () => bluetoothController.connect(target.remoteId),
          cancelPendingConnection: bluetoothController.cancelPendingConnection,
        );
        if (context.mounted &&
            result == BluetoothConnectFeedbackResult.success) {
          Navigator.of(context).pop();
        }
      },
      onDelete: (item) async {
        final target = itemMap[item];
        if (target == null) {
          return;
        }
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
      footerText: context.tr('查找新设备'),
      footerIcon: const Icon(Icons.add_box_outlined, size: 24),
      onFooterTap: () => Navigator.of(context).pop('scan_pairing'),
    );
  }
}

class _ScanDevicesDialogContent extends ConsumerStatefulWidget {
  const _ScanDevicesDialogContent();

  @override
  ConsumerState<_ScanDevicesDialogContent> createState() =>
      _ScanDevicesDialogContentState();
}

class _ScanDevicesDialogContentState
    extends ConsumerState<_ScanDevicesDialogContent> {
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
    super.dispose();
  }

  void _requestStopScanAfterClose() {
    final bluetoothController = ref.read(
      bluetoothDomainControllerProvider.notifier,
    );
    Future<void>.delayed(Duration.zero, () async {
      if (!bluetoothController.mounted) {
        return;
      }
      await bluetoothController.stopScan(
        sessionOwner: BluetoothScanOwner.listPage,
      );
    });
  }

  void _closeDialog() {
    _sessionActive = false;
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    _requestStopScanAfterClose();
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

  Future<void> _connectDevice(ReceiverDeviceView target) async {
    if (!_sessionActive || !mounted) {
      return;
    }
    final result = await showBluetoothConnectFeedback(
      context,
      connect: () => ref
          .read(bluetoothDomainControllerProvider.notifier)
          .connect(target.remoteId),
      cancelPendingConnection: () => ref
          .read(bluetoothDomainControllerProvider.notifier)
          .cancelPendingConnection(),
    );
    if (!_sessionActive || !mounted) {
      return;
    }
    if (result == BluetoothConnectFeedbackResult.success) {
      _closeDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothState = ref.watch(bluetoothDomainControllerProvider);
    final devices = bluetoothState.discoveredDevices;
    final itemMap = <AlertBlueItem, ReceiverDeviceView>{};
    final items = devices
        .map((device) {
          final item = AlertBlueItem(
            title: device.name,
            status: device.isConnected ? context.tr('已连接') : context.tr('未连接'),
            statusColor: device.isConnected
                ? const Color(0xFF00C6FF)
                : Colors.white.withValues(alpha: 0.65),
          );
          itemMap[item] = device;
          return item;
        })
        .toList(growable: false);

    return AlertBlueWidget(
      title: context.tr('去配对'),
      items: items,
      headerLoading: bluetoothState.isScanning || bluetoothState.isWorking,
      onRefresh: bluetoothState.isWorking ? null : _refreshScanWithFeedback,
      emptyText: context.tr('暂无可用蓝牙设备'),
      onTap: (item) async {
        final target = itemMap[item];
        if (target == null) {
          return;
        }
        if (target.isConnected) {
          return;
        }
        await _connectDevice(target);
      },
      onDelete: null,
      onClose: _closeDialog,
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.text,
    required this.onTap,
    required this.icon,
    this.width = 174,
    this.height = 44,
    this.backgroundColor,
    this.gradient,
    this.textColor = AppColors.onPrimary,
  });

  final String text;
  final VoidCallback? onTap;
  final Widget icon;
  final double width;
  final double height;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: gradient,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: AppFonts.s16,
                fontWeight: AppFonts.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

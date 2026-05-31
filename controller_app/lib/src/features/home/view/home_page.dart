import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../../../provider/bluetooth_domain_provider.dart';
import '../../bluetooth/widgets/bluetooth_connect_feedback.dart';

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
  DateTime? _lastHandledPromptAt;
  bool _handlingPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref
            .read(bluetoothDomainControllerProvider.notifier)
            .bootstrapHomeBluetooth(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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

    final connectionState =
        ref.watch(receiverConnectionProvider).valueOrNull ??
        ReceiverConnectionState.disconnected;
    final receiverInfo = ref.watch(receiverInfoProvider).valueOrNull;
    final connectedDevice = bluetoothState.connectedDevice;
    final connected = connectionState == ReceiverConnectionState.connected;
    final batteryLevel = receiverInfo?.batteryLevel;
    final rssi = connectedDevice?.rssi;
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
                              label: 'RX\u7535\u91cf',
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
                              label: '\u4fe1\u53f7\u5f3a\u5ea6',
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
                            text: '\u8bbe\u7f6e',
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
                            text: '\u5f00\u59cb',
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
      builder: (dialogContext) => const _BluetoothEntryDialog(),
    );
    if (!context.mounted) {
      return;
    }
    if (option == 'paired_list') {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: const Color(0xCC000000),
        builder: (_) => const _PairedDevicesDialogContent(),
      );
    } else if (option == 'scan_pairing') {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: const Color(0xCC000000),
        builder: (_) => const _ScanDevicesDialogContent(),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _BluetoothEntryDialog extends StatelessWidget {
  const _BluetoothEntryDialog();

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: 343,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF002149),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xA37DA2CE)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  '\u8bbe\u5907\u5165\u53e3',
                  style: TextStyle(
                    color: Color(0xFFEDF5FF),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                text: '\u5df2\u914d\u5bf9\u8bbe\u5907\u5217\u8868',
                onTap: () => Navigator.of(context).pop('paired_list'),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                text: '\u53bb\u914d\u5bf9',
                onTap: () => Navigator.of(context).pop('scan_pairing'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
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
    final items = devices
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
        .toList(growable: false);

    return AlertBlueWidget(
      title: '\u5df2\u914d\u5bf9\u8bbe\u5907\u5217\u8868',
      items: items,
      emptyText: '\u6682\u65e0\u5386\u53f2\u8bbe\u5907',
      onTap: (item) async {
        final target = devices.firstWhere((d) => d.name == item.title);
        if (target.isConnected) {
          return;
        }
        final result = await showBluetoothConnectFeedback(
          context,
          connect: () => bluetoothController.connect(target.remoteId),
        );
        if (context.mounted &&
            result == BluetoothConnectFeedbackResult.success) {
          Navigator.of(context).pop();
        }
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
    final items = devices
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
        .toList(growable: false);

    return AlertBlueWidget(
      title: '\u53bb\u914d\u5bf9',
      items: items,
      headerLoading: bluetoothState.isScanning || bluetoothState.isWorking,
      onRefresh: bluetoothState.isWorking ? null : _refreshScanWithFeedback,
      emptyText: '\u6682\u65e0\u53ef\u7528\u84dd\u7259\u8bbe\u5907',
      onTap: (item) async {
        final target = devices.firstWhere((d) => d.name == item.title);
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0x661B2D4D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: Color(0xFF0072FF), width: 1),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFFEDF5FF), fontSize: 14),
          ),
        ),
      ),
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
  final VoidCallback onTap;
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

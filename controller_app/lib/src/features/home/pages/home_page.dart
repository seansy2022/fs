import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../../../core/permissions.dart';

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
  bool _autoScanDismissed = false;
  bool _autoScanStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScan();
    });
  }

  Future<void> _startAutoScan() async {
    if (_autoScanStarted) return;
    _autoScanStarted = true;
    await ref.read(receiverRepositoryProvider).startScan();
  }

  @override
  Widget build(BuildContext context) {
    final connectionState =
        ref.watch(receiverConnectionProvider).valueOrNull ??
        ReceiverConnectionState.disconnected;
    final receiverInfo = ref.watch(receiverInfoProvider).valueOrNull;
    final devices = ref.watch(mergedReceiverDevicesProvider);
    final remembered = ref.watch(rememberedDevicesProvider);
    final rememberedIds = remembered.map((device) => device.remoteId).toSet();
    final adapterAsync = ref.watch(adapterStateProvider);

    final connectedDevice = receiverInfo == null
        ? null
        : devices
              .where((device) => device.remoteId == receiverInfo.remoteId)
              .cast<ReceiverScanDevice?>()
              .firstOrNull;

    final connected = connectionState == ReceiverConnectionState.connected;
    final batteryLevel = receiverInfo?.batteryLevel;
    final rssi = connectedDevice?.rssi;
    final deviceName = connectedDevice?.name ?? '--';

    // Auto-scan dialog3: detect online remembered devices
    if (!_autoScanDismissed && connectedDevice == null) {
      final onlineRemembered = devices
          .where(
            (d) =>
                rememberedIds.contains(d.remoteId) &&
                !d.connected &&
                d.rssi > -120,
          )
          .toList(growable: false);
      if (onlineRemembered.isNotEmpty) {
        final firstOnline = onlineRemembered.first;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDialog3(firstOnline);
        });
      }
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图铺满全屏
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
          // 内容
          SafeArea(
            child: Stack(
              children: [
                // 右上角蓝牙连接按钮
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
                    onTap: () {
                      _onBluetoothTap(context, ref, adapterAsync, devices, connectedDevice);
                    },
                  ),
                ),
                // 中间内容
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // RX电压 和 信号强度
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 112,
                            height: 120,
                            child: HomeMetric(
                              label: 'RX电量',
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
                              label: '信号强度',
                              value: rssi != null ? '$rssi' : '--',
                              unit: rssi != null ? 'dBm' : '',
                              emphasize: connected,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // 设置 和 开始 按钮
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HomeActionButton(
                            text: '设置',
                            width: 174,
                            height: 44,
                            backgroundColor: const Color.fromRGBO(27, 45, 77, 1),
                            icon: SvgPicture.asset(
                              'assets/icons/home_settings.svg',
                              width: 15,
                              height: 15,
                            ),
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRoutes.settings);
                            },
                          ),
                          const SizedBox(width: 20),
                          _HomeActionButton(
                            text: '开始',
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
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRoutes.control);
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

  Future<void> _onBluetoothTap(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<AdapterState> adapterAsync,
    List<ReceiverScanDevice> devices,
    ReceiverScanDevice? connectedDevice,
  ) async {
    final adapterState = adapterAsync.valueOrNull ?? AdapterState.unknown;

    if (adapterState != AdapterState.on) {
      // 蓝牙未开启 → 弹窗1
      _showDialog1(context, ref);
    } else {
      // 蓝牙已开启
      final hasPermission = await hasBluetoothPermissions();
      if (!hasPermission) {
        if (context.mounted) {
          final granted = await requestBluetoothPermissions(context);
          if (!granted) return;
        } else {
          return;
        }
      }

      if (connectedDevice != null && connectedDevice.connected) {
        // 已连接 → 弹窗2 (管理连接)
        _showDialog2(context, ref, devices, connectedDevice);
      } else {
        // 未连接 → 显示蓝牙列表弹窗
        _showBluetoothListDialog(context, ref, devices);
      }
    }
  }

  /// 显示蓝牙列表弹窗
  Future<void> _showBluetoothListDialog(
    BuildContext context,
    WidgetRef ref,
    List<ReceiverScanDevice> devices,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xCC000000),
      builder: (dialogContext) => const _BluetoothListDialogContent(),
    );
  }

  /// 弹窗1: 蓝牙未开启，询问是否打开蓝牙
  Future<void> _showDialog1(BuildContext context, WidgetRef ref) async {
    final result = await AlertIconWidget.show(
      context,
      title: '蓝牙未开启',
      message: '需要打开蓝牙才能连接接收机，是否打开蓝牙？',
      cancelText: '否',
      confirmText: '是',
    );
    if (result == true) {
      await ref.read(receiverRepositoryProvider).turnOnAdapter();
      // 等待蓝牙开启
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!context.mounted) return;
      final adapterState = ref.read(receiverRepositoryProvider).adapterState;
      if (adapterState == AdapterState.on) {
        if (context.mounted) {
          Navigator.of(context).pushNamed(AppRoutes.pairing);
        }
      } else {
        // 用户拒绝权限，弹窗保持打开状态（已关闭的状态下等待）
        if (context.mounted) {
          _showDialog1(context, ref);
        }
      }
    }
  }

  /// 弹窗2: 蓝牙已开启，已配对设备列表 / 去配对
  Future<void> _showDialog2(
    BuildContext context,
    WidgetRef ref,
    List<ReceiverScanDevice> devices,
    ReceiverScanDevice? connectedDevice,
  ) async {
    final option = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xCC000000),
      builder: (dialogContext) => const _BluetoothActionDialog(),
    );

    if (!context.mounted) return;

    if (option == 'paired_list') {
      _showBluetoothListDialog(context, ref, devices);
    } else if (option == 'go_pairing') {
      if (connectedDevice?.connected == true) {
        // 已连接接收机 → 弹窗4
        _showDialog4(context);
      } else {
        Navigator.of(context).pushNamed(AppRoutes.pairing);
      }
    }
  }

  /// 弹窗3: 搜索到在线的已配对设备
  Future<void> _showDialog3(ReceiverScanDevice device) async {
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xCC000000),
      builder: (dialogContext) => AlertIconWidget(
        title: '发现已配对设备',
        message: '检测到 ${device.name} 在线，是否连接？',
        cancelText: '不再提示',
        confirmText: '是',
      ),
    );
    if (!mounted) return;
    if (result == true) {
      // 连接此设备
      try {
        await ref.read(receiverRepositoryProvider).connect(device.remoteId);
        await ref.read(rememberedDevicesProvider.notifier).rememberDevice(device);
      } catch (_) {
        // 连接失败静默处理
      }
      _autoScanDismissed = true;
    } else {
      // 不再提示
      _autoScanDismissed = true;
    }
  }

  /// 弹窗4: 已连接接收机，确认断开并去配对
  Future<void> _showDialog4(BuildContext context) async {
    final result = await AlertIconWidget.show(
      context,
      title: '提示',
      message: '已连接接收机，断开当前连接并去配对？',
      cancelText: '否',
      confirmText: '是',
    );
    if (result == true && context.mounted) {
      await ref.read(receiverRepositoryProvider).disconnect();
      if (context.mounted) {
        Navigator.of(context).pushNamed(AppRoutes.pairing);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _BluetoothListDialogContent extends ConsumerStatefulWidget {
  const _BluetoothListDialogContent();

  @override
  ConsumerState<_BluetoothListDialogContent> createState() =>
      _BluetoothListDialogContentState();
}

class _BluetoothListDialogContentState
    extends ConsumerState<_BluetoothListDialogContent> {
  @override
  void initState() {
    super.initState();
    // 打开弹窗自动开始扫描
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receiverRepositoryProvider).startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(mergedReceiverDevicesProvider);
    final remembered = ref.watch(rememberedDevicesProvider);
    final rememberedIds = remembered.map((r) => r.remoteId).toSet();

    final connectionState =
        ref.watch(receiverConnectionProvider).valueOrNull ??
        ReceiverConnectionState.disconnected;
    final isScanning = connectionState == ReceiverConnectionState.scanning;

    final filteredDevices =
        devices.where((d) => d.name.trim().isNotEmpty).toList();

    final items = filteredDevices.map((d) {
      final isRemembered = rememberedIds.contains(d.remoteId);
      String status = '';
      Color? statusColor;

      if (d.connected) {
        status = '正在使用';
        statusColor = const Color(0xFF67E600);
      } else if (isRemembered) {
        // 只有之前连接过的设备才显示“在线/离线”
        if (d.rssi > -120) {
          status = '在线';
          statusColor = const Color(0xFF67E600);
        } else {
          status = '离线';
          statusColor = const Color(0xFFFF8A65);
        }
      } else {
        // 从未连接过的设备显示“未配对”
        status = '未配对';
        statusColor = Colors.white.withValues(alpha: 0.45);
      }

      return AlertBlueItem(
        title: d.name,
        status: status,
        statusColor: statusColor,
      );
    }).toList();

    return AlertBlueWidget(
      title: '已配对设备列表',
      items: items,
      headerLoading: isScanning,
      emptyText: '暂无已识别设备',
      onRefresh: () {
        ref.read(receiverRepositoryProvider).startScan();
      },
      onTap: (item) async {
        final device = filteredDevices.firstWhere((d) => d.name == item.title);
        try {
          await ref.read(receiverRepositoryProvider).connect(device.remoteId);
          await ref
              .read(rememberedDevicesProvider.notifier)
              .rememberDevice(device);
          if (!context.mounted) return;
          Navigator.of(context).pop();
        } catch (e) {
          if (!context.mounted) return;
          AlertIconWidget.show(
            context,
            title: '连接失败',
            message: '无法连接到设备，请重试。',
            confirmText: '知道了',
          );
        }
      },
      onDelete: (item) async {
        final device = filteredDevices.firstWhere((d) => d.name == item.title);
        final confirmed = await AlertIconWidget.show(
          context,
          title: '删除设备',
          message: '确定要删除设备 ${device.name} 吗？',
          cancelText: '取消',
          confirmText: '确定',
        );
        if (confirmed == true) {
          await ref
              .read(rememberedDevicesProvider.notifier)
              .removeDevice(device.remoteId);
        }
      },
      onClose: () => Navigator.of(context).pop(),
    );
  }
}

/// 弹窗2的自定义对话框 — 蓝牙已开启时的操作选择
class _BluetoothActionDialog extends StatelessWidget {
  const _BluetoothActionDialog();

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
                  '蓝牙已开启',
                  style: TextStyle(
                    color: Color(0xFFEDF5FF),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                text: '已配对设备列表',
                onTap: () => Navigator.of(context).pop('paired_list'),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                text: '去配对',
                onTap: () => Navigator.of(context).pop('go_pairing'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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
            style: const TextStyle(
              color: Color(0xFFEDF5FF),
              fontSize: 14,
            ),
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

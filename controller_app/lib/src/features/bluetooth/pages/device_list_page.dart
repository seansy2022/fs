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
  bool _searching = false;
  Timer? _searchTimer;
  int _searchSecondsRemaining = 30;
  String? _connectingRemoteId;
  Timer? _connectionTimeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSearching();
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
    super.dispose();
  }

  void _startSearching() {
    _searchTimer?.cancel();
    setState(() {
      _searching = true;
      _searchSecondsRemaining = 30;
    });
    unawaited(ref.read(receiverRepositoryProvider).startScan());
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _searchSecondsRemaining--;
        if (_searchSecondsRemaining <= 0) {
          _searching = false;
          timer.cancel();
          unawaited(ref.read(receiverRepositoryProvider).stopScan());
        }
      });
    });
  }

  Future<void> _connectToDevice(ReceiverScanDevice device) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _connectingRemoteId = device.remoteId;
    });
    // 30s connection timeout
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      if (_connectingRemoteId == device.remoteId) {
        setState(() {
          _connectingRemoteId = null;
          _busy = false;
        });
        _showConnectionFailedDialog();
      }
    });
    try {
      await ref.read(receiverRepositoryProvider).connect(device.remoteId);
      await ref.read(rememberedDevicesProvider.notifier).rememberDevice(device);
      _connectionTimeoutTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _connectingRemoteId = null;
        _busy = false;
      });
      _showConnectionSuccessDialog();
    } catch (error) {
      _connectionTimeoutTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _connectingRemoteId = null;
        _busy = false;
      });
      _showConnectionFailedDialog();
    }
  }

  void _showConnectionSuccessDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xCC000000),
      builder: (dialogContext) {
        Future<void>.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });
        return const BlueConnectSuccessLoading();
      },
    );
  }

  void _showConnectionFailedDialog() {
    if (!mounted) return;
    AlertIconWidget.show(
      context,
      title: '连接失败',
      message: '连接超时，请确认设备已开机并处于蓝牙模式。',
      confirmText: '知道了',
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(mergedReceiverDevicesProvider);
    final connectedDevice = devices.where((d) => d.connected).firstOrNull;

    return AppPageScaffold(
      title: '已配对设备',
      onBack: () => Navigator.of(context).pop(),
      onRefresh: () {
        _startSearching();
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
                      final isConnecting = _connectingRemoteId == device.remoteId;
                      final isOffline = device.rssi <= -120 && !device.connected;
                      return _DeviceRow(
                        device: device,
                        isConnecting: isConnecting,
                        isOffline: isOffline,
                        isInUse: device.connected,
                        busy: _busy,
                        onTap: () => _onDeviceTap(
                          device,
                          connectedDevice,
                          isConnecting,
                          isOffline,
                        ),
                        onDelete: () => _onDeleteDevice(
                          device,
                          connectedDevice,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 14),
          // 搜索新设备按钮
          _SearchButton(
            searching: _searching,
            secondsRemaining: _searchSecondsRemaining,
            onTap: _startSearching,
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  void _onDeviceTap(
    ReceiverScanDevice device,
    ReceiverScanDevice? connectedDevice,
    bool isConnecting,
    bool isOffline,
  ) {
    if (isConnecting || device.connected || isOffline) return;

    if (connectedDevice != null) {
      // 有正在使用设备 → 弹窗3
      _showSwitchDialog(device, connectedDevice);
    } else {
      // 无正在使用设备 → 直接连接
      unawaited(_connectToDevice(device));
    }
  }

  void _onDeleteDevice(
    ReceiverScanDevice device,
    ReceiverScanDevice? connectedDevice,
  ) {
    if (device.connected) {
      // 正在使用 → 弹窗2
      _showDeleteInUseDialog(device);
    } else {
      // 未使用 → 弹窗1
      _showDeleteDialog(device);
    }
  }

  /// 弹窗1: 删除未使用设备的确认
  Future<void> _showDeleteDialog(ReceiverScanDevice device) async {
    final result = await AlertIconWidget.show(
      context,
      title: '删除设备',
      message: '确定删除 "${device.name}"？\n删除后需要重新配对才能连接。',
      cancelText: '否',
      confirmText: '是',
    );
    if (result == true && mounted) {
      await ref.read(rememberedDevicesProvider.notifier).removeDevice(device.remoteId);
    }
  }

  /// 弹窗2: 删除正在使用设备的确认
  Future<void> _showDeleteInUseDialog(ReceiverScanDevice device) async {
    final result = await AlertIconWidget.show(
      context,
      title: '删除设备',
      message: '"${device.name}" 正在使用，确定断开并删除？\n删除后需要重新配对才能连接。',
      cancelText: '否',
      confirmText: '是',
    );
    if (result == true && mounted) {
      await ref.read(receiverRepositoryProvider).disconnect();
      await ref.read(rememberedDevicesProvider.notifier).removeDevice(device.remoteId);
    }
  }

  /// 弹窗3: 切换设备确认
  Future<void> _showSwitchDialog(
    ReceiverScanDevice newDevice,
    ReceiverScanDevice currentDevice,
  ) async {
    final result = await AlertIconWidget.show(
      context,
      title: '切换设备',
      message: '当前正在使用 "${currentDevice.name}"，\n是否断开并连接 "${newDevice.name}"？',
      cancelText: '否',
      confirmText: '是',
    );
    if (result == true && mounted) {
      await ref.read(receiverRepositoryProvider).disconnect();
      if (mounted) {
        unawaited(_connectToDevice(newDevice));
      }
    }
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.isConnecting,
    required this.isOffline,
    required this.isInUse,
    required this.busy,
    required this.onTap,
    required this.onDelete,
  });

  final ReceiverScanDevice device;
  final bool isConnecting;
  final bool isOffline;
  final bool isInUse;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final canTap = !isConnecting && !isInUse && !isOffline;

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: Panel(
        child: Opacity(
          opacity: isOffline ? 0.5 : 1.0,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: TextStyle(
                        color: isOffline ? AppColors.textDim : AppColors.text,
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
                    _StatusLabel(
                      device: device,
                      isConnecting: isConnecting,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  if (isConnecting)
                    const SizedBox(
                      width: 88,
                      height: 32,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryBright,
                          ),
                        ),
                      ),
                    )
                  else
                    PrimaryButton(
                      text: isInUse ? '已连接' : '连接',
                      width: 88,
                      enabled: !busy && (isInUse || device.rssi > -120),
                      onTap: isInUse ? null : onTap,
                    ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    text: '移除',
                    width: 88,
                    type: PrimaryButtonType.normal,
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.device, required this.isConnecting});

  final ReceiverScanDevice device;
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    if (isConnecting) {
      label = '正在连接';
      color = AppColors.primaryBright;
    } else if (device.connected) {
      label = '正在使用';
      color = AppColors.primaryBright;
    } else if (device.rssi > -120) {
      label = '在线可连接  ${device.rssi} dBm';
      color = AppColors.tertiary;
    } else {
      label = '离线';
      color = AppColors.textDim;
    }

    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: AppFonts.s12,
        fontWeight: AppFonts.w700,
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({
    required this.searching,
    required this.secondsRemaining,
    required this.onTap,
  });

  final bool searching;
  final int secondsRemaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 40,
        child: PrimaryButton(
          text: searching
              ? '搜索中... $secondsRemaining\'s'
              : '搜索新设备',
          enabled: !searching,
          onTap: searching ? null : onTap,
        ),
      ),
    );
  }
}

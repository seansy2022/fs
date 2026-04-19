import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';

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

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState =
        ref.watch(receiverConnectionProvider).valueOrNull ??
        ReceiverConnectionState.disconnected;
    final receiverInfo = ref.watch(receiverInfoProvider).valueOrNull;
    final devices = ref.watch(mergedReceiverDevicesProvider);
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

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图铺满全屏
          Positioned.fill(
            child: Image.asset(
              'assets/images/home.png',
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
                      _showBluetoothDialog(
                        context,
                        ref,
                        devices,
                        connectedDevice,
                      );
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
                              label: 'RX电压',
                              value: batteryLevel != null
                                  ? '$batteryLevel'
                                  : '--',
                              unit: '%',
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
                              unit: 'dBm',
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
                          PrimaryButton(
                            text: '设置',
                            width: 120,
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.settings);
                            },
                          ),
                          const SizedBox(width: 32),
                          PrimaryButton(
                            text: '开始',
                            width: 120,
                            onTap: () {
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

  void _showBluetoothDialog(
    BuildContext context,
    WidgetRef ref,
    List<ReceiverScanDevice> devices,
    ReceiverScanDevice? connectedDevice,
  ) {
    final items = devices
        .where((d) => d.rssi > -120)
        .map(
          (d) => AlertBlueItem(
            title: d.name,
            status: d.connected
                ? '已连接'
                : d.rssi > -120
                ? '在线'
                : '离线',
            statusColor: d.connected
                ? const Color(0xFF67E600)
                : d.rssi > -120
                ? const Color(0xFF67E600)
                : const Color(0xFFFF8A65),
          ),
        )
        .toList();

    AlertBlueWidget.show(
      context,
      title: '蓝牙设备',
      items: items,
      onRefresh: () {
        ref.read(receiverRepositoryProvider).startScan();
      },
      onDelete: (item) {
        // 可以添加删除设备逻辑
      },
    );
  }
}

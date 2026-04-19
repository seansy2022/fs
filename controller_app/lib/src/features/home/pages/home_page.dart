import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
          // 鑳屾櫙鍥鹃摵婊″叏灞?
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
          // 鍐呭
          SafeArea(
            child: Stack(
              children: [
                // 鍙充笂瑙掕摑鐗欒繛鎺ユ寜閽?
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
                // 涓棿鍐呭
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // RX鐢靛帇 鍜?淇″彿寮哄害
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 112,
                            height: 120,
                            child: HomeMetric(
                              label: 'RX鐢靛帇',
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
                              label: '淇″彿寮哄害',
                              value: rssi != null ? '$rssi' : '--',
                              unit: 'dBm',
                              emphasize: connected,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // 璁剧疆 鍜?寮€濮?鎸夐挳
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HomeActionButton(
                            text: '设置',
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
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.settings);
                            },
                          ),
                          const SizedBox(width: 20),
                          _HomeActionButton(
                            text: 'TEST',
                            width: 160,
                            height: 44,
                            enabled: connected || kDebugMode,
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primaryBright,
                                AppColors.primary,
                              ],
                            ),
                            disabledColor: const Color.fromRGBO(27, 45, 77, 1),
                            textColor: AppColors.bg,
                            icon: SvgPicture.asset(
                              'assets/icons/home_start.svg',
                              width: 20,
                              height: 17,
                            ),
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
                ? '鍦ㄧ嚎'
                : '绂荤嚎',
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
      title: '钃濈墮璁惧',
      items: items,
      onRefresh: () {
        ref.read(receiverRepositoryProvider).startScan();
      },
      onDelete: (item) {
        // 鍙互娣诲姞鍒犻櫎璁惧閫昏緫
      },
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
    this.enabled = true,
    this.backgroundColor,
    this.disabledColor,
    this.gradient,
    this.textColor = AppColors.onPrimary,
  });

  final String text;
  final VoidCallback onTap;
  final Widget icon;
  final double width;
  final double height;
  final bool enabled;
  final Color? backgroundColor;
  final Color? disabledColor;
  final Gradient? gradient;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: enabled
              ? backgroundColor
              : (disabledColor ?? const Color.fromRGBO(27, 45, 77, 1)),
          gradient: enabled ? gradient : null,
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
                color: enabled ? textColor : AppColors.textDim,
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

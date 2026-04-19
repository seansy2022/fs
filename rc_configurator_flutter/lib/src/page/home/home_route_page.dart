import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ble/rc_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../provider/app_state_provider.dart';
import '../../provider/bluetooth_provider.dart';
import '../../provider/dashboard_provider.dart';
import '../../provider/functions_provider.dart';
import '../../provider/startup_provider.dart';
import '../../types.dart';
import '../startup_permission.dart';
import 'bluetooth.dart';
import 'dashboard.dart';
import 'enter.dart';
import 'functions.dart';
import 'home_route_utils.dart';
import 'log_settings.dart';

class HomeRoutePage extends ConsumerStatefulWidget {
  const HomeRoutePage({
    super.key,
    required this.secondaryRouteName,
    required this.onRequestPermissions,
  });
  final String secondaryRouteName;
  final Future<void> Function(BuildContext) onRequestPermissions;

  @override
  ConsumerState<HomeRoutePage> createState() => _HomeRoutePageState();
}

class _HomeRoutePageState extends ConsumerState<HomeRoutePage> {
  static const _secretTapCount = 5;
  static const _secretTapWindow = Duration(seconds: 2);
  int _secretTaps = 0;
  String _lastLoggedDashboardChannels = '';
  Timer? _secretTapTimer;

  @override
  void dispose() {
    _secretTapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startup = ref.watch(startupProvider);
    final currentScreen = homeScreen(ref.watch(functionsProvider));
    final bluetooth = ref.read(bluetoothProvider.notifier);
    if (!startup.isReady) return const EnterPage();
    if (!startup.permissionsHandled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(startupProvider.notifier).markPermissionsHandled();
        unawaited(_requestPermissionsAndStartScan(context, bluetooth));
      });
    }
    return TechShell(
      child: Column(
        children: [
          RepaintBoundary(
            child: TopAppBar(
              title: homeTitleFor(currentScreen),
              onRefresh: switch (currentScreen) {
                Screen.bluetooth => bluetooth.startScan,
                Screen.dashboard || Screen.functions => null,
                _ => () => unawaited(
                  ref
                      .read(rcAppStateProvider.notifier)
                      .refreshForScreen(currentScreen),
                ),
              },
              right: _secretTapArea(context, currentScreen),
            ),
          ),
          Expanded(child: _buildBody(context, currentScreen)),
          RepaintBoundary(
            child: BottomNavBar(
              tabs: [
                UiNavTab(
                  label: '首页',
                  iconAsset: AppAssets.tabbarHome,
                  activeIconAsset: AppAssets.tabbarHomeSelected,
                ),
                UiNavTab(
                  label: '菜单',
                  iconAsset: AppAssets.tabbarFunction,
                  activeIconAsset: AppAssets.tabbarFunctionSelected,
                ),
                UiNavTab(
                  label: '蓝牙',
                  iconAsset: AppAssets.tabbarBlue,
                  activeIconAsset: AppAssets.tabbarBlueSelected,
                ),
              ],
              activeIndex: _tabIndexFor(currentScreen),
              onNavigate: (i) => _navigateByTabIndex(context, i),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _secretTapArea(BuildContext context, Screen screen) {
    if (screen != Screen.functions) return null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onSecretTap(context),
      child: const SizedBox(width: 34, height: 34),
    );
  }

  void _onSecretTap(BuildContext context) {
    _secretTapTimer?.cancel();
    _secretTaps += 1;
    if (_secretTaps >= _secretTapCount) {
      _secretTaps = 0;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: BluetoothLogSettingsPage()),
        ),
      );
      return;
    }
    _secretTapTimer = Timer(_secretTapWindow, () {
      _secretTaps = 0;
    });
  }

  Widget _buildBody(BuildContext context, Screen screen) {
    final telemetry = ref.watch(telemetryProvider);
    final channels = ref.watch(channelsProvider);
    final bluetoothState = ref.watch(bluetoothProvider);
    if (screen == Screen.dashboard) _logDashboardChannels(channels);
    return KeyedSubtree(
      key: ValueKey(screen),
      child: switch (screen) {
        Screen.dashboard => Dashboard(
          telemetry: telemetry,
          channels: channels,
          connectedDeviceName: _connectedDeviceName(bluetoothState),
          isBluetoothConnected: bluetoothState.isConnected,
          onNavigate: (s) => _navigate(context, s),
        ),
        Screen.functions => Functions(
          onNavigate: (s) => _navigate(context, s),
        ),
        Screen.bluetooth => Bluetooth(
          settings: bluetoothState,
          onStartScan: ref.read(bluetoothProvider.notifier).startScan,
          onToggleConnection: ref
              .read(bluetoothProvider.notifier)
              .toggleConnection,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  void _logDashboardChannels(List<ChannelState> channels) {
    if (channels.isEmpty) return;
    final snapshot = channels.map((ch) => '${ch.id}=${ch.value}').join(', ');
    if (_lastLoggedDashboardChannels == snapshot) return;
    _lastLoggedDashboardChannels = snapshot;
    RcLogging.link('首页通道值: $snapshot', scope: 'HomeDashboard');
  }

  String _connectedDeviceName(BluetoothSettings settings) {
    final connectedMac = settings.connectedDeviceMac;
    for (final device in settings.devices) {
      if (device.connected) return device.name;
      if (connectedMac != null && device.mac == connectedMac) {
        return device.name;
      }
    }
    return '';
  }

  Future<void> _requestPermissionsAndStartScan(
    BuildContext context,
    BluetoothController bluetooth,
  ) async {
    await widget.onRequestPermissions(context);
    if (!await hasStartupPermissions()) return;
    final settings = ref.read(bluetoothProvider);
    if (settings.isConnected || settings.isConnecting || settings.isScanning) {
      return;
    }
    bluetooth.startScan();
  }

  void _navigate(BuildContext context, Screen screen) {
    if (isHomeScreen(screen)) {
      ref.read(functionsProvider.notifier).navigate(screen);
      return;
    }
    Navigator.of(context).pushNamed(widget.secondaryRouteName, arguments: screen);
  }

  /// 将 [Screen] 映射为底部导航栏的 tab 索引
  int _tabIndexFor(Screen screen) {
    if (screen == Screen.bluetooth) return 2;
    if (screen == Screen.dashboard) return 0;
    return 1; // functions 及其子页面都标记为 index=1（菜单）
  }

  /// 将底部导航栏 tab 索引转换为 [Screen] 并导航
  void _navigateByTabIndex(BuildContext context, int index) {
    final screen = switch (index) {
      0 => Screen.dashboard,
      2 => Screen.bluetooth,
      _ => Screen.functions,
    };
    _navigate(context, screen);
  }
}

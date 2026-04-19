import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../models/app_settings_state.dart';
import '../widgets/settings_workspace.dart';
import 'alarm_settings_page.dart';
import 'channel_settings_page.dart';
import 'failsafe_page.dart';
import 'firmware_upgrade_page.dart';
import 'tank_mixing_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, this.initialRoute = AppRoutes.settings});

  final String initialRoute;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const _routes = <String>[
    AppRoutes.settings,
    AppRoutes.channelSettings,
    AppRoutes.failsafe,
    AppRoutes.tankMixing,
    AppRoutes.alarms,
    AppRoutes.firmware,
  ];

  late String _activeRoute;

  @override
  void initState() {
    super.initState();
    _activeRoute = _routes.contains(widget.initialRoute)
        ? widget.initialRoute
        : AppRoutes.settings;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsWorkspace(
      activeRoute: _activeRoute,
      onBack: () => Navigator.of(context).pop(),
      onMenuSelected: (route) => setState(() => _activeRoute = route),
      content: IndexedStack(
        index: _contentIndex(_activeRoute),
        children: const [
          BasicSettingsContent(),
          ChannelSettingsContent(),
          FailsafeContent(),
          TankMixingContent(),
          AlarmSettingsContent(),
          FirmwareUpgradeContent(),
        ],
      ),
    );
  }

  int _contentIndex(String route) {
    final index = _routes.indexOf(route);
    return index < 0 ? 0 : index;
  }
}

class BasicSettingsContent extends ConsumerWidget {
  const BasicSettingsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1180;
        // final cardWidth = compact ? 138.0 : 176.0;
        const gyroOptions = ['关闭', '方向', 'ALL'];
        final selectedGyroLabel = switch (settings.gyroMode) {
          GyroMode.off => '关闭',
          GyroMode.directionOnly => '方向',
          GyroMode.all => 'ALL',
        };
        return SingleChildScrollView(
          child: Column(
            children: [
              SettingsStrip(
                child: Row(
                  // crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '手型设置',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '右手油门表示右侧区域控制油门\n左手油门表示左侧区域控制油门',
                            style: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Row(
                      children: [
                        _HandModeCard(
                          title: '左手油门',
                          // width: cardWidth,
                          selected:
                              settings.handedness == Handedness.leftThrottle,
                          iconAsset: 'lib/src/assets/svg/l_youmen.svg',
                          onTap: () =>
                              controller.setHandedness(Handedness.leftThrottle),
                        ),
                        const SizedBox(width: 12),
                        _HandModeCard(
                          title: '右手油门',
                          // width: cardWidth,
                          selected:
                              settings.handedness == Handedness.rightThrottle,
                          iconAsset: 'lib/src/assets/svg/r_youmen.svg',
                          onTap: () => controller.setHandedness(
                            Handedness.rightThrottle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SettingsStrip(
                child: Row(
                  // crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '操控模式',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '固定位置表示从固定起点开始操控 隐藏可变位置表示任意起点开始。',
                            style: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Row(
                      children: [
                        _HandModeCard(
                          // width: cardWidth,
                          title: '固定位置',
                          iconAsset: 'lib/src/assets/svg/guding.svg',
                          selected:
                              settings.controlMode == ControlMode.fixedPosition,
                          onTap: () => controller.setControlMode(
                            ControlMode.fixedPosition,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _HandModeCard(
                          // width: cardWidth,
                          title: '隐藏可变位置',
                          iconAsset: 'lib/src/assets/svg/hidden.svg',
                          selected:
                              settings.controlMode == ControlMode.floating,
                          onTap: () =>
                              controller.setControlMode(ControlMode.floating),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SettingsStrip(
                // height: 96,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '陀螺仪设置',
                        style: TextStyle(color: AppColors.text, fontSize: 14),
                      ),
                    ),
                    RcMultiToggle<String>(
                      options: gyroOptions,
                      selected: selectedGyroLabel,
                      width: compact ? 180 : 220,
                      height: 34,
                      fontSize: 14,
                      onChanged: (value) =>
                          controller.setGyroMode(switch (value) {
                            '关闭' => GyroMode.off,
                            '方向' => GyroMode.directionOnly,
                            _ => GyroMode.all,
                          }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SettingsStrip(
                // height: 120,
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '设置接收机退出蓝牙模式',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                            ),
                          ),
                          // SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HandModeCard extends StatelessWidget {
  const _HandModeCard({
    required this.title,
    // required this.width,
    required this.selected,
    required this.iconAsset,
    required this.onTap,
  });

  final String title;
  // final double width;
  final bool selected;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RCButton(
      onTap: onTap,
      width: 80,
      height: 72,
      active: selected,
      enableRepeat: false,
      direction: Axis.vertical,
      gap: 10,
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
      iconWidget: SvgPicture.asset(
        iconAsset,
        width: 54,
        height: 28,
        fit: BoxFit.contain,
      ),
      textWidget: Text(
        title,
        style: TextStyle(
          color: selected ? AppColors.text : AppColors.textDim,
          fontSize: 10,
        ),
      ),
    );
  }
}

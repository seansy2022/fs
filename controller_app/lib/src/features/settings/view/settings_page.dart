import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

import 'package:rc_c_ble/rc_c_ble.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../../../provider/bluetooth_domain_provider.dart';
import '../models/app_settings_state.dart';
import '../widgets/settings_workspace.dart';
import 'alarm_settings_page.dart';
import 'channel_settings_page.dart';
import 'failsafe_page.dart';
import 'firmware_upgrade_page.dart';
import 'help_center_page.dart';
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
    AppRoutes.help,
  ];

  late String _activeRoute;

  @override
  void initState() {
    super.initState();
    _activeRoute = _routes.contains(widget.initialRoute)
        ? widget.initialRoute
        : AppRoutes.settings;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref
            .read(bluetoothDomainControllerProvider.notifier)
            .ensureScanStopped(),
      );
    });
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
          HelpCenterContent(),
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
      builder: (context, _) {
        const gyroOptions = ['方向', '油门', 'all'];
        final selectedGyroLabel = switch (settings.gyroMode) {
          GyroMode.directionOnly => '方向',
          GyroMode.throttleOnly => '油门',
          GyroMode.all => 'all',
        };

        return SingleChildScrollView(
          child: Column(
            children: [
              SettingsStrip(
                child: Row(
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
                          selected:
                              settings.handedness == Handedness.leftThrottle,
                          iconAsset: 'lib/src/assets/svg/l_youmen.svg',
                          onTap: () =>
                              controller.setHandedness(Handedness.leftThrottle),
                        ),
                        const SizedBox(width: 12),
                        _HandModeCard(
                          title: '右手油门',
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
                            '固定位置表示从固定起点开始操控，\n隐藏可变位置表示任意起点开始。',
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
                      width: 74.0 * gyroOptions.length,
                      height: 28,
                      fontSize: 14,
                      fontWeight: AppFonts.w400,
                      uppercaseLabels: false,
                      onChanged: (value) =>
                          controller.setGyroMode(switch (value) {
                            '方向' => GyroMode.directionOnly,
                            '油门' => GyroMode.throttleOnly,
                            _ => GyroMode.all,
                          }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SettingsStrip(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onExitBleModeTap(context, ref),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          '设置接收机退出蓝牙模式',
                          style: TextStyle(color: AppColors.text, fontSize: 14),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textDim,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SettingsStrip(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onBackgroundMusicTap(context, ref),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '背景音乐',
                          style: TextStyle(color: AppColors.text, fontSize: 14),
                        ),
                      ),
                      Text(
                        _backgroundMusicDisplayName(settings),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textDim,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _onExitBleModeTap(BuildContext context, WidgetRef ref) async {
  final connectionState =
      ref.read(receiverConnectionProvider).valueOrNull ??
      ReceiverConnectionState.disconnected;

  if (connectionState == ReceiverConnectionState.connected) {
    final result = await AlertIconWidget.show(
      context,
      title: '退出蓝牙模式',
      message: '确定退出蓝牙模式？\n退出后需要重新连接才能控制。',
      cancelText: '否',
      confirmText: '是',
    );
    if (result == true && context.mounted) {
      try {
        await ref.read(receiverRepositoryProvider).exitBleMode();
        if (context.mounted) {
          await ref.read(receiverRepositoryProvider).disconnect();
          if (context.mounted) {
            await AlertIconWidget.show(
              context,
              title: '已退出',
              message: '接收机已退出蓝牙模式。',
              confirmText: '确定',
            );
          }
        }
      } catch (_) {
        if (context.mounted) {
          await AlertIconWidget.show(
            context,
            title: '操作失败',
            message: '退出蓝牙模式失败，请重试。',
            confirmText: '确定',
          );
        }
      }
    }
  } else {
    await AlertIconWidget.show(
      context,
      title: '退出蓝牙模式',
      message: '当前未连接接收机，无需退出蓝牙模式。',
      confirmText: '确定',
    );
  }
}

Future<void> _onBackgroundMusicTap(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(appSettingsProvider);
  final selectedAction =
      settings.backgroundMusicMode == BackgroundMusicMode.defaultTrack
      ? _BackgroundMusicAction.defaultTrack
      : _BackgroundMusicAction.localTrack;
  final action = await showDialog<_BackgroundMusicAction>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xCC000000),
    builder: (dialogContext) =>
        _BackgroundMusicDialog(selectedAction: selectedAction),
  );

  if (!context.mounted) {
    return;
  }

  switch (action) {
    case _BackgroundMusicAction.defaultTrack:
      ref
          .read(appSettingsProvider.notifier)
          .updateBackgroundMusic(
            mode: BackgroundMusicMode.defaultTrack,
            name: '默认',
          );
    case _BackgroundMusicAction.localTrack:
      FilePickerResult? selected;
      try {
        // Use audio picker mode for broader plugin compatibility, then filter.
        selected = await FilePicker.pickFiles(
          type: FileType.audio,
          allowMultiple: false,
          withData: false,
        );
      } on MissingPluginException {
        if (!context.mounted) {
          return;
        }
        await AlertIconWidget.show(
          context,
          title: '文件选择不可用',
          message: '当前环境未注册文件选择插件，请重启应用后重试。',
          confirmText: '确定',
        );
        return;
      } on PlatformException catch (_) {
        if (!context.mounted) {
          return;
        }
        await AlertIconWidget.show(
          context,
          title: '选择失败',
          message: '打开本地文件失败，请重试。',
          confirmText: '确定',
        );
        return;
      }
      if (!context.mounted) {
        return;
      }
      final files = selected?.files;
      if (files == null || files.isEmpty) {
        return;
      }
      final file = files.first;
      final extension = file.extension?.toLowerCase();
      if (extension != 'mp3' && extension != 'wav') {
        await AlertIconWidget.show(
          context,
          title: '格式不支持',
          message: '仅支持 MP3 或 WAV 音频文件。',
          confirmText: '确定',
        );
        return;
      }
      ref
          .read(appSettingsProvider.notifier)
          .updateBackgroundMusic(
            mode: BackgroundMusicMode.localTrack,
            name: file.name,
          );
    case null:
      return;
  }
}

String _backgroundMusicDisplayName(AppSettingsState settings) {
  if (settings.backgroundMusicMode == BackgroundMusicMode.defaultTrack ||
      settings.backgroundMusicName == '默认背景音乐') {
    return '默认';
  }
  return settings.backgroundMusicName;
}

enum _BackgroundMusicAction { defaultTrack, localTrack }

class _BackgroundMusicDialog extends StatelessWidget {
  const _BackgroundMusicDialog({required this.selectedAction});

  final _BackgroundMusicAction selectedAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: 343,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2D4D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(
                          '背景音乐',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: AppFonts.w600,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 44,
                        height: 60,
                        child: Icon(
                          Icons.cancel_outlined,
                          color: AppColors.textDim,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFF233854)),
              _BackgroundMusicOptionRow(
                label: '默认背景音乐',
                selected: selectedAction == _BackgroundMusicAction.defaultTrack,
                onTap: () => Navigator.of(
                  context,
                ).pop(_BackgroundMusicAction.defaultTrack),
              ),
              const Divider(
                height: 0.5,
                thickness: 0.5,
                color: Color(0xFF233854),
              ),
              _BackgroundMusicOptionRow(
                label: '选择本地音乐',
                selected: selectedAction == _BackgroundMusicAction.localTrack,
                onTap: () => Navigator.of(
                  context,
                ).pop(_BackgroundMusicAction.localTrack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundMusicOptionRow extends StatelessWidget {
  const _BackgroundMusicOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                  ),
                ),
                if (selected)
                  SvgPicture.string(
                    _kOptionCheckedSvg,
                    key: ValueKey('bg-music-check-$label'),
                    width: 17.0,
                    height: 11.0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _kOptionCheckedSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="37.000732421875" height="26.00048828125" viewBox="0 0 37.000732421875 26.00048828125" fill="none"><path stroke="rgba(0, 198, 255, 1)" stroke-width="4" stroke-linejoin="round" stroke-linecap="round" d="M2 13.0002L13.0002 24.0005L35.0007 2"></path></svg>';

class _HandModeCard extends StatelessWidget {
  const _HandModeCard({
    required this.title,
    required this.selected,
    required this.iconAsset,
    required this.onTap,
  });

  final String title;
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

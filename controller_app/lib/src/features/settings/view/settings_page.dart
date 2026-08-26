import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers.dart';
import '../../../provider/bluetooth_domain_provider.dart';
import '../../../provider/receiver_ble_mode_provider.dart';
import '../models/app_settings_state.dart';
import '../language/language_setting_section.dart';
import '../widgets/settings_workspace.dart';
import 'alarm_settings_page.dart';
import 'channel_settings_page.dart';
import 'failsafe_page.dart';
import 'firmware_upgrade_page.dart';
import 'gear/gear_settings_page.dart';
import 'gyro/gyro_control_section.dart';
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
    AppRoutes.gearSettings,
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
          GearSettingsContent(),
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
    final handSettingsEnabled = settings.gyroMode == GyroMode.off;

    return LayoutBuilder(
      builder: (context, _) {
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
                        children: [
                          Text(
                            context.tr('手型设置'),
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            context.tr(
                              '单手右边：右边区域控制油门方向\n'
                              '单手左边：左边区域控制油门方向\n'
                              '右手油门：右边区域控制油门\n'
                              '左手油门：左边区域控制油门',
                            ),
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Row(
                      children: [
                        _HandModeCard(
                          title: '单手右边',
                          enabled: handSettingsEnabled,
                          selected:
                              settings.handedness == Handedness.singleRight,
                          iconAsset:
                              'lib/src/assets/svg/single_hand_right_option.svg',
                          onTap: () =>
                              controller.setHandedness(Handedness.singleRight),
                        ),
                        const SizedBox(width: 8),
                        _HandModeCard(
                          title: '单手左边',
                          enabled: handSettingsEnabled,
                          selected:
                              settings.handedness == Handedness.singleLeft,
                          iconAsset:
                              'lib/src/assets/svg/single_hand_left_option.svg',
                          onTap: () =>
                              controller.setHandedness(Handedness.singleLeft),
                        ),
                        const SizedBox(width: 8),
                        _HandModeCard(
                          title: '右手油门',
                          enabled: handSettingsEnabled,
                          selected:
                              settings.handedness == Handedness.rightThrottle,
                          iconAsset: 'lib/src/assets/svg/r_youmen.svg',
                          onTap: () => controller.setHandedness(
                            Handedness.rightThrottle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HandModeCard(
                          title: '左手油门',
                          enabled: handSettingsEnabled,
                          selected:
                              settings.handedness == Handedness.leftThrottle,
                          iconAsset: 'lib/src/assets/svg/l_youmen.svg',
                          onTap: () =>
                              controller.setHandedness(Handedness.leftThrottle),
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
                        children: [
                          Text(
                            context.tr('操控模式'),
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            context.tr('固定位置表示从固定起点开始操控，\n隐藏可变位置表示任意起点开始。'),
                            style: const TextStyle(
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
              const GyroControlSection(),
              const SizedBox(height: 8),
              SettingsStrip(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onExitBleModeTap(context, ref),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('设置接收机退出蓝牙模式'),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                          ),
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
                      Expanded(
                        child: Text(
                          context.tr('背景音乐'),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        context.tr(_backgroundMusicDisplayName(settings)),
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
              const SizedBox(height: 8),
              const LanguageSettingSection(),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _onExitBleModeTap(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(receiverBleModeControllerProvider);

  if (!controller.isConnected) {
    if (context.mounted) {
      await AlertIconWidget.show(
        context,
        title: AppText.tr('退出蓝牙模式'),
        message: AppText.tr('当前未连接接收机，无需退出蓝牙模式。'),
        confirmText: AppText.tr('确定'),
      );
    }
    return;
  }

  final result = await AlertIconWidget.show(
    context,
    title: AppText.tr('退出蓝牙模式'),
    message: AppText.tr('确定退出蓝牙模式？\n退出后需要重新连接才能控制。'),
    cancelText: AppText.tr('否'),
    confirmText: AppText.tr('是'),
  );
  if (result == true && context.mounted) {
    final exitResult = await controller.exitBleModeAndDisconnect();
    if (!context.mounted) {
      return;
    }
    if (exitResult == ReceiverBleModeExitResult.success) {
      await AlertIconWidget.show(
        context,
        title: AppText.tr('已退出'),
        message: AppText.tr('接收机已退出蓝牙模式。'),
        confirmText: AppText.tr('确定'),
      );
      return;
    }
    await AlertIconWidget.show(
      context,
      title: AppText.tr('操作失败'),
      message: AppText.tr('退出蓝牙模式失败，请重试。'),
      confirmText: AppText.tr('确定'),
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
          title: AppText.tr('文件选择不可用'),
          message: AppText.tr('当前环境未注册文件选择插件，请重启应用后重试。'),
          confirmText: AppText.tr('确定'),
        );
        return;
      } on PlatformException catch (_) {
        if (!context.mounted) {
          return;
        }
        await AlertIconWidget.show(
          context,
          title: AppText.tr('选择失败'),
          message: AppText.tr('打开本地文件失败，请重试。'),
          confirmText: AppText.tr('确定'),
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
          title: AppText.tr('格式不支持'),
          message: AppText.tr('仅支持 MP3 或 WAV 音频文件。'),
          confirmText: AppText.tr('确定'),
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
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(
                          AppText.tr('背景音乐'),
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
                    AppText.tr(label),
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
    this.hasEmbeddedTitle = false,
    this.enabled = true,
    required this.selected,
    required this.iconAsset,
    required this.onTap,
  });

  final String title;
  final bool hasEmbeddedTitle;
  final bool enabled;
  final bool selected;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizedTitle = context.tr(title);
    final useCompactFont =
        Localizations.localeOf(context).languageCode == 'en' &&
        localizedTitle.length > 12;
    final iconWidget = SizedBox(
      height: 32,
      child: hasEmbeddedTitle
          ? ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 0.56,
                child: SvgPicture.asset(
                  iconAsset,
                  width: 64,
                  fit: BoxFit.contain,
                ),
              ),
            )
          : Center(
              child: SvgPicture.asset(
                iconAsset,
                width: 40,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
    );

    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: RCButton(
          onTap: onTap,
          width: 64,
          height: 58,
          active: enabled && selected,
          enableRepeat: false,
          direction: Axis.vertical,
          gap: 3,
          padding: EdgeInsets.zero,
          // 单手 SVG 底部带有中文图形文字；裁掉该区域后统一使用可本地化标题。
          iconWidget: iconWidget,
          // 所有选项均由文字层显示，确保语言切换时不受 SVG 内嵌文字影响。
          textWidget: Text(
            localizedTitle,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: enabled && selected ? AppColors.text : AppColors.textDim,
              fontSize: useCompactFont ? 7 : 8,
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../core/providers.dart';
import '../../settings/models/app_settings_state.dart';
import '../controllers/control_controller.dart';

class ControlPage extends ConsumerStatefulWidget {
  const ControlPage({super.key});

  @override
  ConsumerState<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends ConsumerState<ControlPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_activate());
    });
  }

  Future<void> _activate() async {
    final repository = ref.read(receiverRepositoryProvider);
    if (repository.receiverInfo != null) {
      await ref.read(controlControllerProvider.notifier).activate();
    }
  }

  @override
  void dispose() {
    unawaited(ref.read(controlControllerProvider.notifier).deactivate());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(receiverInfoProvider).valueOrNull;
    final devices = ref.watch(mergedReceiverDevicesProvider);
    final controlState = ref.watch(controlControllerProvider);
    final controlController = ref.read(controlControllerProvider.notifier);
    final settings = ref.watch(appSettingsProvider);

    final connectedDevice = info == null
        ? null
        : devices
              .where((device) => device.remoteId == info.remoteId)
              .cast<ReceiverScanDevice?>()
              .firstOrNull;
    final batteryLevel = info?.batteryLevel ?? 0;
    final rssi = connectedDevice?.rssi;

    final leftPadIsThrottle = settings.handedness == Handedness.leftThrottle;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              'assets/images/control.png',
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
                // 左上角返回按钮
                Positioned(
                  top: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: SizedBox(
                      width: 129,
                      height: 49,
                      child: SvgPicture.asset(
                        'assets/icons/home_back.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // 主内容
                Column(
                  children: [
                    // 顶部栏
                    _TopBar(
                      battery: batteryLevel,
                      rssi: rssi,
                      onLight: controlController.toggleHeadlights,
                      lightOn: controlState.headlightsOn,
                      onDirection: () {},
                      directionOn: false,
                      onNetwork: controlController.toggleGyro,
                      networkOn: controlState.gyroEnabled,
                    ),
                    const SizedBox(height: 8),
                    // 顶下部
                    _TopLowerBar(
                      musicOn: controlState.backgroundMusicOn,
                      soundOn: controlState.soundEffectsOn,
                      onMusic: controlController.toggleBackgroundMusic,
                      onSound: controlController.toggleSoundEffects,
                    ),
                    const SizedBox(height: 8),
                    // 中下部
                    Expanded(
                      child: _ControlArea(
                        leftPadIsThrottle: leftPadIsThrottle,
                        controlState: controlState,
                        controlController: controlController,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 顶部栏
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.battery,
    required this.rssi,
    required this.onLight,
    required this.lightOn,
    required this.onDirection,
    required this.directionOn,
    required this.onNetwork,
    required this.networkOn,
  });

  final int battery;
  final int? rssi;
  final VoidCallback onLight;
  final bool lightOn;
  final VoidCallback onDirection;
  final bool directionOn;
  final VoidCallback onNetwork;
  final bool networkOn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 129), // 为左上角返回按钮留空间
          // 左边：信号 + 电池
          RCButton(
            iconWidget: Icon(
              Icons.network_wifi,
              color: AppColors.primaryBright,
              size: 16,
            ),
            textWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${rssi ?? '--'} dBm',
                  style: const TextStyle(color: AppColors.text, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.battery_full,
                  color: const Color(0xFF67E600),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$battery%',
                  style: const TextStyle(color: AppColors.text, fontSize: 12),
                ),
              ],
            ),
            isRounded: true,
            onTap: () {},
          ),
          const Spacer(),
          // // 中间：状态提示
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //   decoration: BoxDecoration(
          //     color: AppColors.surfaceHighest.withValues(alpha: 0.5),
          //     borderRadius: BorderRadius.circular(8),
          //     border: Border.all(
          //       color: AppColors.primary.withValues(alpha: 0.3),
          //     ),
          //   ),
          //   child: const Text(
          //     '正常连接',
          //     style: TextStyle(color: AppColors.onPrimary, fontSize: 14),
          //   ),
          // ),
          // const Spacer(),
          //  右边：图标按钮
          Row(
            children: [
              _CircleIconBtn(
                icon: Icons.lightbulb_outline,
                active: lightOn,
                onTap: onLight,
              ),
              const SizedBox(width: 8),
              _CircleIconBtn(
                icon: Icons.explore,
                active: directionOn,
                onTap: onDirection,
              ),
              const SizedBox(width: 8),
              _CircleIconBtn(
                icon: Icons.gps_fixed,
                active: networkOn,
                onTap: onNetwork,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 顶下部
class _TopLowerBar extends StatelessWidget {
  const _TopLowerBar({
    required this.musicOn,
    required this.soundOn,
    required this.onMusic,
    required this.onSound,
  });

  final bool musicOn;
  final bool soundOn;
  final VoidCallback onMusic;
  final VoidCallback onSound;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 左边：音乐 + 声音
          RCIconButton(
            icon: musicOn ? Icons.music_note : Icons.music_off,
            active: musicOn,
            onTap: onMusic,
          ),
          const SizedBox(width: 8),
          RCIconButton(
            icon: soundOn ? Icons.volume_up : Icons.volume_off,
            active: soundOn,
            onTap: onSound,
          ),
          const Spacer(),
          // 中间：操作图标状态
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Color(0xFF67E600), size: 8),
                const SizedBox(width: 6),
                const Text(
                  '运行中',
                  style: TextStyle(color: AppColors.textDim, fontSize: 12),
                ),
              ],
            ),
          ),
          const Spacer(),
          // 右边：自定义按钮
          RCButton(
            iconWidget: const Icon(
              Icons.settings,
              color: AppColors.text,
              size: 18,
            ),
            textWidget: const Text(
              '设置',
              style: TextStyle(color: AppColors.text, fontSize: 12),
            ),
            isRounded: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  const _CircleIconBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0x6600C6FF) : AppColors.surfaceHighest,
          border: Border.all(
            color: active ? const Color(0xFF00C6FF) : AppColors.primary,
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppColors.onPrimary : AppColors.textDim,
        ),
      ),
    );
  }
}

// 中下部控制区域
class _ControlArea extends StatelessWidget {
  const _ControlArea({
    required this.leftPadIsThrottle,
    required this.controlState,
    required this.controlController,
  });

  final bool leftPadIsThrottle;
  final ControlScreenState controlState;
  final ControlController controlController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 左边：操作条 + 垂直控制按钮
          Expanded(
            child: Column(
              children: [
                // _TrimHorizontalStrip(
                //   trim: controlState.trim,
                //   onMinus: () => controlController.adjustTrim(-1),
                //   onPlus: () => controlController.adjustTrim(1),
                // ),
                // const SizedBox(height: 8),
                Expanded(
                  child: ControlSlider(
                    direction: ControlSliderDirection.vertical,
                    onChanged: (value) {
                      final normalized = value / 100.0;
                      controlController.setThrottle(normalized);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 中间：移动动画
          // Expanded(
          //   child: _TrackCenter(
          //     throttle: controlState.throttle,
          //     steering: controlState.steering,
          //   ),
          // ),
          const SizedBox(width: 16),
          // 右边：操作条 + 水平控制按钮
          Expanded(
            child: Column(
              children: [
                RcDriveModeSwitch(
                  mode: controlState.highGear
                      ? RcDriveMode.high
                      : RcDriveMode.low,
                  onChanged: (mode) {
                    controlController.toggleGear(mode == RcDriveMode.high);
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ControlSlider(
                          direction: ControlSliderDirection.horizontal,
                          onChanged: (value) {
                            final normalized = value / 100.0;
                            controlController.setSteering(normalized);
                          },
                        ),
                      ),
                      // const SizedBox(width: 8),
                      // _ThrottleVerticalStrip(
                      //   value: controlState.throttle,
                      //   onIncrease: () {
                      //     final next = (controlState.throttle + 0.05)
                      //         .clamp(-1.0, 1.0)
                      //         .toDouble();
                      //     unawaited(controlController.setThrottle(next));
                      //   },
                      //   onDecrease: () {
                      //     final next = (controlState.throttle - 0.05)
                      //         .clamp(-1.0, 1.0)
                      //         .toDouble();
                      //     unawaited(controlController.setThrottle(next));
                      //   },
                      // ),
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
}

class _TrimHorizontalStrip extends StatelessWidget {
  const _TrimHorizontalStrip({
    required this.trim,
    required this.onMinus,
    required this.onPlus,
  });

  final int trim;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final normalized = ((trim + 50) / 100).clamp(0.0, 1.0);
    return Row(
      children: [
        RCIconButton(plus: false, onTap: onMinus, size: 48, iconSize: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 16,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final center = width / 2;
                    final thumb = normalized * width;
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B2D4D),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Positioned(
                          left: thumb >= center ? center : thumb,
                          width: (thumb - center).abs().clamp(0.0, width),
                          top: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: thumb >= center
                                  ? AppGradients.primary
                                  : AppGradients.primaryReverse,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Positioned(
                          left: center - 1,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 2, color: AppColors.outline),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // const SizedBox(height: 4),
              // Text(
              //   '方向微调 $trim',
              //   style: const TextStyle(color: AppColors.textDim, fontSize: 13),
              // ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        RCIconButton(plus: true, onTap: onPlus, size: 48, iconSize: 24),
      ],
    );
  }
}

class _ThrottleVerticalStrip extends StatelessWidget {
  const _ThrottleVerticalStrip({
    required this.value,
    required this.onIncrease,
    required this.onDecrease,
  });

  final double value;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final normalized = ((value + 1) / 2).clamp(0.0, 1.0);
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          RCIconButton(plus: false, onTap: onDecrease, size: 46, iconSize: 20),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF1B2D4D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Align(
                alignment: Alignment(0, normalized * 2 - 1),
                child: Container(
                  width: 10,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryVertical,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          RCIconButton(plus: true, onTap: onIncrease, size: 46, iconSize: 20),
        ],
      ),
    );
  }
}

class _TrackCenter extends StatelessWidget {
  const _TrackCenter({required this.throttle, required this.steering});

  final double throttle;
  final double steering;

  @override
  Widget build(BuildContext context) {
    final intensity = (throttle.abs() + steering.abs()).clamp(0.0, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ChevronGroup(upward: true, intensity: intensity),
        const SizedBox(height: 12),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.18 + intensity * 0.28),
                AppColors.primaryBright.withValues(
                  alpha: 0.09 + intensity * 0.2,
                ),
              ],
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.52),
            ),
          ),
          child: const Icon(
            Icons.sports_motorsports,
            color: AppColors.primaryBright,
            size: 80,
          ),
        ),
        const SizedBox(height: 12),
        _ChevronGroup(upward: false, intensity: intensity),
      ],
    );
  }
}

class _ChevronGroup extends StatelessWidget {
  const _ChevronGroup({required this.upward, required this.intensity});

  final bool upward;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) {
        final alpha = (0.16 + index * 0.12 + intensity * 0.3).clamp(0.0, 1.0);
        return Icon(
          upward ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: AppColors.primaryBright.withValues(alpha: alpha),
          size: 48,
        );
      }),
    );
  }
}

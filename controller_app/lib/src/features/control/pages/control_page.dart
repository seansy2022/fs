import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../core/providers.dart';
import '../../settings/models/app_settings_state.dart';
import '../controllers/control_controller.dart';
import '../widgets/floating_control_zone.dart';

class ControlPage extends ConsumerStatefulWidget {
  const ControlPage({super.key});

  @override
  ConsumerState<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends ConsumerState<ControlPage> {
  static const _backgroundVideoAsset =
      'assets/wepb/control_bg_forward_loop.mp4';
  static const _forwardBackgroundAsset = 'assets/wepb/control_forward.webp';
  static const _forwardLeftBackgroundAsset =
      'assets/wepb/control_forward_left.webp';
  static const _forwardRightBackgroundAsset =
      'assets/wepb/control_forward_right.webp';
  static const _reverseBackgroundAsset = 'assets/wepb/control_reverse.webp';
  static const _reverseLeftBackgroundAsset =
      'assets/wepb/control_reverse_left.webp';
  static const _reverseRightBackgroundAsset =
      'assets/wepb/control_reverse_right.webp';
  static const _movementThreshold = 0.15;
  static const _overlayAnimationWidth = 136.0;
  static const _overlayAnimationHeight = 216.0;

  VideoPlayerController? _backgroundVideoController;
  bool _backgroundVideoReady = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeBackgroundVideo());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_activate());
    });
  }

  Future<void> _initializeBackgroundVideo() async {
    final controller = VideoPlayerController.asset(_backgroundVideoAsset);
    _backgroundVideoController = controller;
    try {
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.initialize();
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _backgroundVideoReady = true;
      });
    } catch (_) {
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _backgroundVideoReady = false;
      });
    }
  }

  Future<void> _activate() async {
    final repository = ref.read(receiverRepositoryProvider);
    if (repository.receiverInfo != null) {
      await ref.read(controlControllerProvider.notifier).activate();
    }
  }

  @override
  void dispose() {
    final backgroundVideoController = _backgroundVideoController;
    _backgroundVideoController = null;
    unawaited(backgroundVideoController?.dispose());
    unawaited(ref.read(controlControllerProvider.notifier).deactivate());
    super.dispose();
  }

  String? _movementBackgroundAsset(ControlScreenState controlState) {
    final throttle = controlState.throttle;
    final steering = controlState.steering;

    if (throttle > _movementThreshold) {
      if (steering < -_movementThreshold) {
        return _forwardLeftBackgroundAsset;
      }
      if (steering > _movementThreshold) {
        return _forwardRightBackgroundAsset;
      }
      return _forwardBackgroundAsset;
    }

    if (throttle < -_movementThreshold) {
      if (steering < -_movementThreshold) {
        return _reverseLeftBackgroundAsset;
      }
      if (steering > _movementThreshold) {
        return _reverseRightBackgroundAsset;
      }
      return _reverseBackgroundAsset;
    }

    return null;
  }

  Widget _buildBackground(ControlScreenState controlState) {
    final movementBackgroundAsset = _movementBackgroundAsset(controlState);
    final controller = _backgroundVideoController;

    final baseBackground =
        _backgroundVideoReady &&
            controller != null &&
            controller.value.isInitialized
        ? FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          )
        : Image.asset(
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
          );

    if (movementBackgroundAsset == null) {
      return baseBackground;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: baseBackground),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: _overlayAnimationWidth,
            height: _overlayAnimationHeight,
            child: Image.asset(
              movementBackgroundAsset,
              key: ValueKey<String>(movementBackgroundAsset),
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ),
      ],
    );
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
    const topControlAnchorTop = 65.0;
    const audioButtonsSize = 36.0;
    const driveModeSwitchHeight = 48.0;
    const driveModeTop =
        topControlAnchorTop - ((driveModeSwitchHeight - audioButtonsSize) / 2);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildBackground(controlState)),

          SafeArea(
            child: Stack(
              children: [
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
                Positioned(
                  top: topControlAnchorTop, // 49(back button height) + 16
                  left: 40,
                  child: _TopLowerBar(
                    musicOn: controlState.backgroundMusicOn,
                    soundOn: controlState.soundEffectsOn,
                    onMusic: controlController.toggleBackgroundMusic,
                    onSound: controlController.toggleSoundEffects,
                  ),
                ),
                Positioned(
                  top: driveModeTop,
                  right: 40,
                  child: RcDriveModeSwitch(
                    mode: controlState.highGear
                        ? RcDriveMode.high
                        : RcDriveMode.low,
                    onChanged: (mode) {
                      controlController.toggleGear(mode == RcDriveMode.high);
                    },
                  ),
                ),
                // 涓诲唴瀹?
                Column(
                  children: [
                    _TopBar(
                      battery: batteryLevel,
                      rssi: rssi,
                      onLight: controlController.toggleHeadlights,
                      lightOn: controlState.headlightsOn,
                      onDirection: controlController.toggleSliderButtons,
                      directionOn: controlState.sliderButtonsVisible,
                      onNetwork: controlController.toggleGyro,
                      networkOn: controlState.gyroEnabled,
                    ),
                    const SizedBox(height: 52),

                    Expanded(
                      child: _ControlArea(
                        leftPadIsThrottle: leftPadIsThrottle,
                        controlMode: settings.controlMode,
                        gyroMode: settings.gyroMode,
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
          const SizedBox(width: 129), //
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

          Row(
            children: [
              _CircleIconBtn(
                icon: Icons.lightbulb_outline,
                active: lightOn,
                onTap: onLight,
              ),
              const SizedBox(width: 16),
              _CircleIconBtn(
                icon: Icons.explore,
                active: directionOn,
                onTap: onDirection,
              ),
              const SizedBox(width: 16),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // const SizedBox(width: 147), // 129(back width) + 18(gap)
        _CircleIconBtn(
          icon: musicOn ? Icons.music_note : Icons.music_off,
          active: musicOn,
          onTap: onMusic,
        ),
        const SizedBox(width: 16),
        _CircleIconBtn(
          icon: soundOn ? Icons.volume_up : Icons.volume_off,
          active: soundOn,
          onTap: onSound,
        ),
      ],
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

// 涓笅閮ㄦ帶鍒跺尯鍩?
class _ControlArea extends StatelessWidget {
  static const _controlGap = 35.0;
  static const _verticalControlLeft = 40.0;
  static const _horizontalControlBottom = 20.0;

  const _ControlArea({
    required this.leftPadIsThrottle,
    required this.controlMode,
    required this.gyroMode,
    required this.controlState,
    required this.controlController,
  });

  final bool leftPadIsThrottle;
  final ControlMode controlMode;
  final GyroMode gyroMode;
  final ControlScreenState controlState;
  final ControlController controlController;

  bool get _useFloatingStickStyle =>
      controlMode == ControlMode.floating || gyroMode == GyroMode.all;

  Widget _buildVerticalStick() {
    if (_useFloatingStickStyle) {
      return FloatingControlZone(
        direction: FloatingControlDirection.vertical,
        onChanged: (value) {
          unawaited(controlController.setThrottle(value));
        },
      );
    }

    return Control(
      direction: ControlSliderDirection.vertical,
      onChanged: (value) {
        controlController.setThrottle(value / 100);
      },
    );
  }

  Widget _buildHorizontalStick() {
    if (_useFloatingStickStyle) {
      return FloatingControlZone(
        direction: FloatingControlDirection.horizontal,
        onChanged: (value) {
          unawaited(controlController.setSteering(value));
        },
      );
    }

    return Control(
      direction: ControlSliderDirection.horizontal,
      onChanged: (value) {
        controlController.setSteering(value / 100);
      },
    );
  }

  Widget _buildVerticalArea({
    required bool sliderOnOuterSide,
    Widget? controlOverride,
  }) {
    final slider = RCControllSider(
      direction: RCControllSiderDirection.vertical,
      showButtons: controlState.sliderButtonsVisible,
      onChanged: (value) {
        controlController.setThrottle(value);
      },
    );

    final stick = controlOverride ?? _buildVerticalStick();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: sliderOnOuterSide
          ? [slider, const SizedBox(width: _controlGap), stick]
          : [stick, const SizedBox(width: _controlGap), slider],
    );
  }

  Widget _buildHorizontalArea({Widget? controlOverride}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        controlOverride ?? _buildHorizontalStick(),
        const SizedBox(height: _controlGap),
        RCControllSider(
          direction: RCControllSiderDirection.horizontal,
          showButtons: controlState.sliderButtonsVisible,
          onChanged: (value) {
            controlController.setSteering(value);
          },
        ),
      ],
    );
  }

  Widget _buildDirectionalStick({required bool positiveThrottle}) {
    return SizedBox(
      width: 160,
      height: 260,
      child: FloatingControlZone(
        direction: FloatingControlDirection.vertical,
        allowPositive: positiveThrottle,
        allowNegative: !positiveThrottle,
        onChanged: (value) {
          final nextValue = positiveThrottle ? value : -value;
          unawaited(controlController.setThrottle(nextValue));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leftControlOverride = gyroMode == GyroMode.directionOnly
        ? _buildDirectionalStick(positiveThrottle: false)
        : null;
    final rightControlOverride = gyroMode == GyroMode.directionOnly
        ? _buildDirectionalStick(positiveThrottle: true)
        : null;

    final leftArea = leftPadIsThrottle
        ? _buildVerticalArea(
            sliderOnOuterSide: true,
            controlOverride: leftControlOverride,
          )
        : _buildHorizontalArea(controlOverride: leftControlOverride);
    final rightArea = leftPadIsThrottle
        ? _buildHorizontalArea(controlOverride: rightControlOverride)
        : _buildVerticalArea(
            sliderOnOuterSide: false,
            controlOverride: rightControlOverride,
          );

    return Padding(
      padding: const EdgeInsets.only(
        left: _verticalControlLeft,
        right: 16,
        bottom: _horizontalControlBottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [leftArea, rightArea],
      ),
    );
  }
}

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
import '../widgets/trim_control.dart';

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
    final connectionState =
        ref.watch(receiverConnectionProvider).valueOrNull ??
        ReceiverConnectionState.disconnected;
    final controlState = ref.watch(controlControllerProvider);
    final controlController = ref.read(controlControllerProvider.notifier);
    final settings = ref.watch(appSettingsProvider);

    final connected = connectionState == ReceiverConnectionState.connected;
    final connectedDevice = info == null
        ? null
        : devices
              .where((device) => device.remoteId == info.remoteId)
              .cast<ReceiverScanDevice?>()
              .firstOrNull;
    final batteryLevel = connected ? (info?.batteryLevel ?? 0) : 0;
    final rssi = connected ? connectedDevice?.rssi : null;

    final channelFunctions = settings.channels.map((c) => c.function).toSet();
    final showHeadlight = channelFunctions.contains(AuxiliaryFunction.headlight);
    final showWarningLight = channelFunctions.contains(AuxiliaryFunction.warningLight);
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
                // Main content column
                Column(
                  children: [
                    // Only show top bar when connected
                    if (connected)
                      _TopBar(
                        battery: batteryLevel,
                        rssi: rssi,
                        showHeadlight: showHeadlight,
                        headlightOn: controlState.headlightsOn,
                        onHeadlight: controlController.toggleHeadlights,
                        showWarningLight: showWarningLight,
                        warningLightOn: controlState.warningLightsOn,
                        onWarningLight: controlController.toggleWarningLights,
                        onDirection: controlController.toggleSliderButtons,
                        directionOn: controlState.sliderButtonsVisible,
                        onNetwork: controlController.toggleGyro,
                        networkOn: controlState.gyroEnabled,
                      ),
                    if (!connected) const SizedBox(height: 16),

                    // Trim switch
                    if (connected)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Spacer(),
                            _TrimToggle(
                              value: controlState.sliderButtonsVisible,
                              onChanged: (_) => controlController.toggleSliderButtons(),
                            ),
                          ],
                        ),
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
    required this.showHeadlight,
    required this.headlightOn,
    required this.onHeadlight,
    required this.showWarningLight,
    required this.warningLightOn,
    required this.onWarningLight,
    required this.onDirection,
    required this.directionOn,
    required this.onNetwork,
    required this.networkOn,
  });

  final int battery;
  final int? rssi;
  final bool showHeadlight;
  final bool headlightOn;
  final VoidCallback onHeadlight;
  final bool showWarningLight;
  final bool warningLightOn;
  final VoidCallback onWarningLight;
  final VoidCallback onDirection;
  final bool directionOn;
  final VoidCallback onNetwork;
  final bool networkOn;

  @override
  Widget build(BuildContext context) {
    final List<Widget> lightButtons = [];
    if (showHeadlight) {
      lightButtons.add(_CircleIconBtn.svg(
        assetPath: 'assets/icons/wifi_signal.svg',
        active: headlightOn,
        onTap: onHeadlight,
      ));
    }
    if (showWarningLight) {
      if (lightButtons.isNotEmpty) {
        lightButtons.add(const SizedBox(width: 16));
      }
      lightButtons.add(_CircleIconBtn(
        icon: Icons.flash_on,
        active: warningLightOn,
        onTap: onWarningLight,
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 129),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SignalWidget(
                value: _rssiToPercent(rssi).toDouble(),
                width: 29,
                height: 16,
              ),
              const SizedBox(width: 16),
              BatteryWidget(
                value: battery.toDouble(),
                width: 29,
                height: 16,
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              ...lightButtons,
              if (lightButtons.isNotEmpty) const SizedBox(width: 16),
              _CircleIconBtn.svg(
                assetPath: 'assets/icons/sync_arrows.svg',
                active: directionOn,
                onTap: onDirection,
              ),
              const SizedBox(width: 16),
              _CircleIconBtn.svg(
                assetPath: 'assets/icons/broadcast.svg',
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

int _rssiToPercent(int? rssi) {
  if (rssi == null) return 0;
  if (rssi >= -50) return 100;
  if (rssi >= -65) return 75;
  if (rssi >= -80) return 50;
  if (rssi >= -95) return 25;
  return 0;
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
        _CircleIconBtn.svg(
          assetPath: musicOn
              ? 'assets/icons/music_on.svg'
              : 'assets/icons/music_off.svg',
          active: musicOn,
          onTap: onMusic,
        ),
        const SizedBox(width: 16),
        _CircleIconBtn.svg(
          assetPath: soundOn
              ? 'assets/icons/sound_on.svg'
              : 'assets/icons/sound_off.svg',
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
  }) : assetPath = null;

  const _CircleIconBtn.svg({
    required this.assetPath,
    required this.active,
    required this.onTap,
  }) : icon = null;

  final IconData? icon;
  final String? assetPath;
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
        child: assetPath != null
            ? Padding(
                padding: const EdgeInsets.all(9),
                child: SvgPicture.asset(
                  assetPath!,
                  fit: BoxFit.contain,
                ),
              )
            : Icon(
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

class _TrimToggle extends StatelessWidget {
  const _TrimToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? const Color(0x6600C6FF) : AppColors.surfaceHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? const Color(0xFF00C6FF) : AppColors.primary,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '微调',
              style: TextStyle(
                color: value ? AppColors.onPrimary : AppColors.textDim,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              value ? Icons.toggle_on : Icons.toggle_off,
              size: 18,
              color: value ? const Color(0xFF00C6FF) : AppColors.textDim,
            ),
          ],
        ),
      ),
    );
  }
}

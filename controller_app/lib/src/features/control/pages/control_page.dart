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
    const topControlAnchorTop = 65.0;
    const audioButtonsSize = 36.0;
    const driveModeSwitchHeight = 48.0;
    const driveModeTop =
        topControlAnchorTop - ((driveModeSwitchHeight - audioButtonsSize) / 2);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                      onDirection: () {},
                      directionOn: false,
                      onNetwork: controlController.toggleGyro,
                      networkOn: controlState.gyroEnabled,
                    ),
                    const SizedBox(height: 52),

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
    required this.controlState,
    required this.controlController,
  });

  final bool leftPadIsThrottle;
  final ControlScreenState controlState;
  final ControlController controlController;

  Widget _buildVerticalArea() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        RCControllSider(
          direction: RCControllSiderDirection.vertical,
          initialValue: controlState.throttle,
          onChanged: (value) {
            controlController.setThrottle(value);
          },
        ),
        const SizedBox(width: _controlGap),
        Control(
          direction: ControlSliderDirection.vertical,
          onChanged: (value) {
            controlController.setThrottle(value / 100);
          },
        ),
      ],
    );
  }

  Widget _buildHorizontalArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Control(
          direction: ControlSliderDirection.horizontal,
          onChanged: (value) {
            controlController.setSteering(value / 100);
          },
        ),
        const SizedBox(height: _controlGap),
        RCControllSider(
          direction: RCControllSiderDirection.horizontal,
          initialValue: controlState.steering,
          onChanged: (value) {
            controlController.setSteering(value);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final leftArea = leftPadIsThrottle
        ? _buildVerticalArea()
        : _buildHorizontalArea();
    final rightArea = leftPadIsThrottle
        ? _buildHorizontalArea()
        : _buildVerticalArea();

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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../core/providers.dart';
import '../../../provider/bluetooth_domain_provider.dart';
import '../../../provider/control_presentation_provider.dart';
import '../../../provider/control_provider.dart';
import '../../../provider/race_sound_player.dart';
import '../../settings/models/app_settings_state.dart';
import '../controllers/control_controller.dart';
import '../widgets/bluetooth_svg_toggle_button.dart';
import '../widgets/control_aux_action_panel.dart';
import '../widgets/gyro_svg_toggle_button.dart';
import '../widgets/steering_indicator_row.dart';
import '../widgets/throttle_turn_signal_buttons.dart';
import '../widgets/trim_svg_toggle_button.dart';

const gyroHintUpArrowKey = gyroDirectionalThrottleUpArrowKey;
const gyroHintDownArrowKey = gyroDirectionalThrottleDownArrowKey;
const gyroHintDotKey = gyroDirectionalThrottleDotKey;
const gyroHintThumbKey = gyroDirectionalThrottleThumbKey;
const gyroHintSliderProbeKey = ValueKey<String>('gyro-hint-slider-probe');
const gyroHintStickProbeKey = ValueKey<String>('gyro-hint-stick-probe');

bool shouldUseGyroControlOverride({
  required bool gyroEnabled,
  required GyroMode gyroMode,
}) {
  return gyroEnabled && gyroMode != GyroMode.all;
}

bool isLeftTurnState(ControlAnimationState state) {
  return state == ControlAnimationState.forwardLeft ||
      state == ControlAnimationState.reverseLeft;
}

bool isRightTurnState(ControlAnimationState state) {
  return state == ControlAnimationState.forwardRight ||
      state == ControlAnimationState.reverseRight;
}

@visibleForTesting
Widget buildGyroDirectionVerticalAlignmentPreviewForTest({
  required bool upArrow,
  ValueChanged<double>? onChanged,
}) {
  final slider = KeyedSubtree(
    key: gyroHintSliderProbeKey,
    child: const RCControllSider(direction: RCControllSiderDirection.vertical),
  );
  final stick = KeyedSubtree(
    key: gyroHintStickProbeKey,
    child: GyroDirectionalThrottleControl(
      positiveThrottle: upArrow,
      floating: false,
      showArrowHint: true,
      onChanged: onChanged ?? _noopDoubleControlChanged,
    ),
  );
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [slider, const SizedBox(width: 18), stick],
  );
}

void _noopDoubleControlChanged(double _) {}

ChannelSetting channelSettingAt(List<ChannelSetting> channels, int index) {
  if (index < channels.length) {
    return channels[index];
  }
  return ChannelSetting(
    channelLabel: 'CH${index + 1}',
    title: '辅助通道',
    function: AuxiliaryFunction.none,
    displayName: '辅助${index - 1}',
    controlType: AuxControlType.disabled,
    switchValues: const <double>[100, -100],
    multiStateValues: const <double>[0, 0, 0],
    singleValue: 0,
    lowPercent: -100,
    highPercent: 100,
    trimPercent: 0,
    reversed: false,
  );
}

List<AuxControlButtonViewData> buildAuxButtons({
  required int channelIndex,
  required ChannelSetting setting,
  required AuxChannelRuntimeState runtime,
  required ControlController controller,
}) {
  if (setting.controlType == AuxControlType.disabled) {
    return const <AuxControlButtonViewData>[];
  }
  final labels = auxChannelControlLabels(setting, runtime);
  if (setting.controlType == AuxControlType.multiState) {
    return List<AuxControlButtonViewData>.generate(labels.length, (index) {
      return AuxControlButtonViewData(
        key: ValueKey<String>(
          'control-top-action-ch$channelIndex-state-$index',
        ),
        label: labels[index],
        active: false,
        flashOnTap: true,
        onTap: () {
          unawaited(
            controller.pressAuxChannel(channelIndex, selectedIndex: index),
          );
        },
      );
    });
  }
  return <AuxControlButtonViewData>[
    AuxControlButtonViewData(
      key: ValueKey<String>('control-top-action-ch$channelIndex'),
      label: labels.first,
      active: setting.controlType == AuxControlType.switchControl
          ? runtime.switchOn
          : false,
      flashOnTap: setting.controlType == AuxControlType.value,
      onTap: () {
        unawaited(controller.pressAuxChannel(channelIndex));
      },
    ),
  ];
}

class ControlPage extends ConsumerStatefulWidget {
  const ControlPage({super.key});

  @override
  ConsumerState<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends ConsumerState<ControlPage> {
  static const _backgroundVideoAsset =
      'assets/wepb/control_bg_forward_loop.mp4';
  static const _overlayAnimationWidth = 136.0;
  static const _overlayAnimationHeight = 216.0;

  VideoPlayerController? _backgroundVideoController;
  bool _backgroundVideoReady = false;
  ControlController? _controlController;
  ProviderSubscription<ControlScreenState>?
  _presentationControlStateSubscription;

  ControlController _getControlController() {
    final cached = _controlController;
    if (cached != null) {
      return cached;
    }
    final controller = ref.read(controlControllerProvider.notifier);
    _controlController = controller;
    return controller;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_initializeBackgroundVideo());
    final presentationController = ref.read(
      controlPresentationProvider.notifier,
    );
    _presentationControlStateSubscription = ref
        .listenManual<ControlScreenState>(controlControllerProvider, (_, next) {
          unawaited(presentationController.bindControlState(next));
        }, fireImmediately: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final initialState = ref.read(controlControllerProvider);
      unawaited(presentationController.bindControlState(initialState));
      unawaited(
        ref
            .read(bluetoothDomainControllerProvider.notifier)
            .ensureScanStopped(),
      );
      unawaited(presentationController.enterPage());
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
      await _getControlController().activate();
    }
  }

  Future<void> _handleGyroToggle() async {
    await _getControlController().toggleGyro();
  }

  @override
  void dispose() {
    final backgroundVideoController = _backgroundVideoController;
    _backgroundVideoController = null;
    _controlController = null;
    _presentationControlStateSubscription?.close();
    _presentationControlStateSubscription = null;
    unawaited(backgroundVideoController?.dispose());
    super.dispose();
  }

  Widget _buildBackground(ControlAnimationState animationState) {
    final movementBackgroundAsset = overlayAnimationAssetFor(animationState);
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
    final connectedRssi = ref.watch(connectedRssiProvider).valueOrNull;
    final controlState = ref.watch(controlControllerProvider);
    final controlController = ref.read(controlControllerProvider.notifier);
    final presentationState = ref.watch(controlPresentationProvider);
    final presentationController = ref.read(
      controlPresentationProvider.notifier,
    );
    _controlController = controlController;
    final settings = ref.watch(appSettingsProvider);
    final ch3Setting = channelSettingAt(settings.channels, 2);
    final ch4Setting = channelSettingAt(settings.channels, 3);
    final leftTurnActive =
        presentationState.effectCue == SoundCue.leftTurnSignal;
    final rightTurnActive =
        presentationState.effectCue == SoundCue.rightTurnSignal;

    final connected = connectionState == ReceiverConnectionState.connected;
    final connectedDevice = info == null
        ? null
        : devices
              .where((device) => device.remoteId == info.remoteId)
              .cast<ReceiverScanDevice?>()
              .firstOrNull;
    final batteryLevel = connected ? (info?.batteryLevel ?? 0) : 0;
    final rssi = connected ? (connectedRssi ?? connectedDevice?.rssi) : null;

    final showThrottleTurnSignals = leftTurnActive || rightTurnActive;
    final gyroControlEnabled = controlState.gyroEnabled;
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
            child: _buildBackground(presentationState.animationState),
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
                if (gyroControlEnabled)
                  Positioned(
                    top: driveModeTop,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SteeringIndicatorRow(
                        steering: controlState.steering,
                        throttle: controlState.throttle,
                        itemCount: settings.gyroMode == GyroMode.all ? 2 : 1,
                        singleType: settings.gyroMode == GyroMode.throttleOnly
                            ? SingleIndicatorType.throttle
                            : SingleIndicatorType.steering,
                        size: 48,
                        gap: 40,
                      ),
                    ),
                  ),
                Positioned(
                  top: driveModeTop,
                  left: 40,
                  child: ControlAuxActionPanel(
                    auxButtons: [
                      ...buildAuxButtons(
                        channelIndex: 2,
                        setting: ch3Setting,
                        runtime: controlState.ch3Runtime,
                        controller: controlController,
                      ),
                      ...buildAuxButtons(
                        channelIndex: 3,
                        setting: ch4Setting,
                        runtime: controlState.ch4Runtime,
                        controller: controlController,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: driveModeTop,
                  right: 40,
                  child: RcDriveModeSwitch(
                    mode: controlState.parkLocked
                        ? RcDriveMode.park
                        : controlState.highGear
                        ? RcDriveMode.high
                        : RcDriveMode.low,
                    lowLabel: '低速',
                    highLabel: '高速',
                    onChanged: (mode) => switch (mode) {
                      RcDriveMode.park => unawaited(
                        controlController.setParkLocked(true),
                      ),
                      RcDriveMode.high => unawaited(
                        controlController.toggleGear(true),
                      ),
                      RcDriveMode.low => unawaited(
                        controlController.toggleGear(false),
                      ),
                    },
                  ),
                ),
                // Main content column
                Column(
                  children: [
                    _TopBar(
                      battery: batteryLevel,
                      rssi: rssi,
                      musicOn: presentationState.backgroundSoundEnabled,
                      onMusic: () {
                        unawaited(
                          presentationController.toggleBackgroundSound(),
                        );
                      },
                      soundOn: presentationState.effectSoundEnabled,
                      onSound: () {
                        unawaited(presentationController.toggleEffectSound());
                      },
                      onDirection: controlController.toggleSliderButtons,
                      directionOn: controlState.sliderButtonsVisible,
                      onNetwork: () {
                        unawaited(_handleGyroToggle());
                      },
                      networkOn: controlState.gyroEnabled,
                      showThrottleTurnSignals: showThrottleTurnSignals,
                      leftTurnOn: leftTurnActive,
                      rightTurnOn: rightTurnActive,
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
                              onChanged: (_) =>
                                  controlController.toggleSliderButtons(),
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
                        inputLocked: controlState.parkLocked,
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
    required this.musicOn,
    required this.onMusic,
    required this.soundOn,
    required this.onSound,
    required this.onDirection,
    required this.directionOn,
    required this.onNetwork,
    required this.networkOn,
    required this.showThrottleTurnSignals,
    required this.leftTurnOn,
    required this.rightTurnOn,
  });

  final int battery;
  final int? rssi;
  final bool musicOn;
  final VoidCallback onMusic;
  final bool soundOn;
  final VoidCallback onSound;
  final VoidCallback onDirection;
  final bool directionOn;
  final VoidCallback onNetwork;
  final bool networkOn;
  final bool showThrottleTurnSignals;
  final bool leftTurnOn;
  final bool rightTurnOn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 49,
      child: Padding(
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
                BatteryWidget(value: battery.toDouble(), width: 29, height: 16),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                if (showThrottleTurnSignals && (leftTurnOn || rightTurnOn)) ...[
                  ThrottleTurnSignalButtons(
                    leftOn: leftTurnOn,
                    rightOn: rightTurnOn,
                    size: 36,
                  ),
                  const SizedBox(width: 16),
                ],
                BluetoothSvgToggleButton(value: musicOn, onTap: onMusic),
                const SizedBox(width: 16),
                SoundSvgToggleButton(value: soundOn, onTap: onSound),
                const SizedBox(width: 16),
                _CircleIconBtn.svg(
                  assetPath: 'assets/icons/sync_arrows.svg',
                  active: directionOn,
                  onTap: onDirection,
                ),
                const SizedBox(width: 16),
                GyroSvgToggleButton(
                  value: networkOn,
                  onTap: onNetwork,
                  size: 36,
                ),
              ],
            ),
          ],
        ),
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
                child: SvgPicture.asset(assetPath!, fit: BoxFit.contain),
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
  static const _controlGap = 18.0;
  static const _verticalControlLeft = 40.0;
  static const _horizontalControlBottom = 20.0;
  static const _floatingVerticalZoneWidth = 160.0;
  static const _floatingVerticalZoneHeight = 260.0;
  static const _floatingHorizontalZoneWidth = 260.0;
  static const _floatingHorizontalZoneHeight = 160.0;

  const _ControlArea({
    required this.leftPadIsThrottle,
    required this.controlMode,
    required this.gyroMode,
    required this.controlState,
    required this.controlController,
    required this.inputLocked,
  });

  final bool leftPadIsThrottle;
  final ControlMode controlMode;
  final GyroMode gyroMode;
  final ControlScreenState controlState;
  final ControlController controlController;
  final bool inputLocked;

  bool get _useFloatingStickStyle => controlMode == ControlMode.floating;

  Widget _buildVerticalStick() {
    if (_useFloatingStickStyle) {
      return VerticalFloatingControlZone(
        width: _floatingVerticalZoneWidth,
        height: _floatingVerticalZoneHeight,
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
        width: _floatingHorizontalZoneWidth,
        height: _floatingHorizontalZoneHeight,
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
      lockSignUntilRelease: true,
      onChanged: (value) {
        controlController.setThrottle(value);
      },
    );

    final stick = controlOverride ?? _buildVerticalStick();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
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

  Widget _buildFloatingDirectionalThrottleStick({
    required bool positiveThrottle,
    bool showArrowHint = false,
  }) {
    return GyroDirectionalThrottleControl(
      positiveThrottle: positiveThrottle,
      floating: true,
      showArrowHint: showArrowHint,
      floatingWidth: _floatingVerticalZoneWidth,
      floatingHeight: _floatingVerticalZoneHeight,
      onChanged: (value) {
        unawaited(controlController.setThrottle(value));
      },
    );
  }

  Widget _buildFixedDirectionalThrottleStick({
    required bool positiveThrottle,
    bool showArrowHint = false,
  }) {
    return GyroDirectionalThrottleControl(
      positiveThrottle: positiveThrottle,
      floating: false,
      showArrowHint: showArrowHint,
      onChanged: (value) {
        controlController.setThrottle(value);
      },
    );
  }

  Widget _buildFloatingDirectionalSteeringStick({
    required bool positiveSteering,
  }) {
    return FloatingControlZone(
      direction: FloatingControlDirection.horizontal,
      width: _floatingHorizontalZoneWidth,
      height: _floatingHorizontalZoneHeight,
      allowPositive: positiveSteering,
      allowNegative: !positiveSteering,
      onChanged: (value) {
        unawaited(controlController.setSteering(value));
      },
    );
  }

  Widget _buildFixedDirectionalSteeringStick({required bool positiveSteering}) {
    return Control(
      direction: ControlSliderDirection.horizontal,
      allowPositive: positiveSteering,
      allowNegative: !positiveSteering,
      onChanged: (value) {
        controlController.setSteering(value / 100);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final useFloatingOverride = controlMode == ControlMode.floating;
    final useGyroOverride = shouldUseGyroControlOverride(
      gyroEnabled: controlState.gyroEnabled,
      gyroMode: gyroMode,
    );
    final showGyroDirectionHint =
        useGyroOverride && gyroMode == GyroMode.directionOnly;
    final leftControlOverride = !useGyroOverride
        ? null
        : gyroMode == GyroMode.directionOnly
        ? useFloatingOverride
              ? _buildFloatingDirectionalThrottleStick(
                  positiveThrottle: false,
                  showArrowHint: showGyroDirectionHint,
                )
              : _buildFixedDirectionalThrottleStick(
                  positiveThrottle: false,
                  showArrowHint: showGyroDirectionHint,
                )
        : gyroMode == GyroMode.throttleOnly
        ? useFloatingOverride
              ? _buildFloatingDirectionalSteeringStick(positiveSteering: false)
              : _buildFixedDirectionalSteeringStick(positiveSteering: false)
        : null;
    final rightControlOverride = !useGyroOverride
        ? null
        : gyroMode == GyroMode.directionOnly
        ? useFloatingOverride
              ? _buildFloatingDirectionalThrottleStick(
                  positiveThrottle: true,
                  showArrowHint: showGyroDirectionHint,
                )
              : _buildFixedDirectionalThrottleStick(
                  positiveThrottle: true,
                  showArrowHint: showGyroDirectionHint,
                )
        : gyroMode == GyroMode.throttleOnly
        ? useFloatingOverride
              ? _buildFloatingDirectionalSteeringStick(positiveSteering: true)
              : _buildFixedDirectionalSteeringStick(positiveSteering: true)
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

    return AbsorbPointer(
      absorbing: inputLocked,
      child: Padding(
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
      ),
    );
  }
}

class _TrimToggle extends StatelessWidget {
  const _TrimToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return TrimSvgToggleButton(
      value: value,
      onTap: () => onChanged(!value),
      size: 36,
    );
  }
}

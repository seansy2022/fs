import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../../../provider/alert_message_provider.dart';
import '../../../provider/bluetooth_domain_provider.dart';
import '../../../provider/control_presentation_provider.dart';
import '../../../provider/control_provider.dart';
import '../../../provider/device_status_provider.dart';
import '../../../provider/effective_bluetooth_provider.dart';
import '../../../provider/race_sound_player.dart';
import '../../../provider/signal_strength_utils.dart';
import '../../settings/models/app_settings_state.dart';
import '../controllers/control_controller.dart';
import '../widgets/bluetooth_svg_toggle_button.dart';
import '../widgets/control_aux_action_panel.dart';
import '../widgets/control_status_warning_text.dart';
import '../widgets/directional_steering_button.dart';
import '../widgets/gyro_svg_toggle_button.dart';
import '../widgets/single_hand_control/single_hand_layouts.dart';
import '../widgets/steering_indicator_row.dart';
import '../widgets/throttle_turn_signal_buttons.dart';

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
  return gyroEnabled && gyroMode != GyroMode.off;
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

/// 返回当前语言下适合遥控器小按钮显示的紧凑挡位标签。
String compactDriveModeLabel(BuildContext context, {required bool high}) {
  if (Localizations.localeOf(context).languageCode == 'zh') {
    return high ? '高速' : '低速';
  }
  return high ? 'HIGH' : 'LOW';
}

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
    multiStateValues: const <double>[-100, 0, 100],
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
    final resolved = resolveAuxChannelRuntime(setting, runtime);
    return <AuxControlButtonViewData>[
      AuxControlButtonViewData(
        key: ValueKey<String>('control-top-action-ch$channelIndex-label'),
        label: setting.displayName,
        active: false,
        labelOnly: true,
        onTap: () {},
      ),
      AuxControlButtonViewData(
        key: ValueKey<String>('control-top-action-ch$channelIndex'),
        label: labels[resolved.selectedIndex],
        active: true,
        onTap: () => unawaited(controller.pressAuxChannel(channelIndex)),
      ),
    ];
  }
  return <AuxControlButtonViewData>[
    AuxControlButtonViewData(
      key: ValueKey<String>('control-top-action-ch$channelIndex'),
      label: labels.first,
      active: setting.controlType == AuxControlType.switchControl
          ? runtime.switchOn
          : setting.controlType == AuxControlType.value,
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

class _ControlPageState extends ConsumerState<ControlPage>
    with WidgetsBindingObserver {
  static const _backgroundVideoAsset =
      'assets/wepb/control_bg_forward_loop.mp4';
  static const _overlayAnimationWidth = 136.0;
  static const _overlayAnimationHeight = 216.0;

  VideoPlayerController? _backgroundVideoController;
  bool _backgroundVideoReady = false;
  ControlController? _controlController;
  ProviderSubscription<ControlScreenState>?
  _presentationControlStateSubscription;
  ProviderSubscription<ReceiverConnectionState>? _connectionSubscription;
  Timer? _countdownTimer;
  int? _countdownValue = 3;
  bool _countdownCompleted = false;
  bool _activationInProgress = false;
  bool _controlSessionStopped = false;

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
    WidgetsBinding.instance.addObserver(this);
    _getControlController().prepareControlSession();
    unawaited(_initializeBackgroundVideo());
    final presentationController = ref.read(
      controlPresentationProvider.notifier,
    );
    _presentationControlStateSubscription = ref
        .listenManual<ControlScreenState>(controlControllerProvider, (_, next) {
          unawaited(presentationController.bindControlState(next));
        }, fireImmediately: false);
    _connectionSubscription = ref.listenManual<ReceiverConnectionState>(
      effectiveReceiverConnectionProvider,
      (previous, next) {
        // 倒计时结束后才允许连接事件启动连续控制帧。
        if (previous != next && next == ReceiverConnectionState.connected) {
          unawaited(_activateWhenReady());
        }
      },
      fireImmediately: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializePage(presentationController));
    });
  }

  /// 恢复本地运行状态后再开始倒计时，避免按默认状态发送控制数据。
  Future<void> _initializePage(
    ControlPresentationController presentationController,
  ) async {
    await _getControlController().restoreInputRuntime();
    if (!mounted) {
      return;
    }
    final initialState = ref.read(controlControllerProvider);
    await presentationController.bindControlState(initialState);
    unawaited(
      ref.read(bluetoothDomainControllerProvider.notifier).ensureScanStopped(),
    );
    unawaited(presentationController.enterPage());
    _startCountdown();
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

  /// 以每秒一次的节奏显示 3、2、1；完成前不允许发送控制帧。
  void _startCountdown() {
    _countdownTimer?.cancel();
    _getControlController().pauseControlOutputForCountdown();
    var nextValue = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      nextValue -= 1;
      if (nextValue == 0) {
        timer.cancel();
        _countdownTimer = null;
        setState(() {
          _countdownValue = null;
          _countdownCompleted = true;
        });
        _getControlController().prepareControlSession();
        unawaited(_activateWhenReady());
        return;
      }
      setState(() => _countdownValue = nextValue);
    });
  }

  /// 倒计时结束且接收机已连接时，只启动一次控制循环。
  Future<void> _activateWhenReady() async {
    if (_controlSessionStopped ||
        !_countdownCompleted ||
        _activationInProgress ||
        ref.read(effectiveReceiverConnectionProvider) !=
            ReceiverConnectionState.connected) {
      return;
    }
    if (ref.read(controlControllerProvider).loopActive) {
      return;
    }
    _activationInProgress = true;
    try {
      await _getControlController().activate();
    } finally {
      _activationInProgress = false;
    }
  }

  Future<void> _handleGyroToggle() async {
    await _getControlController().toggleGyro();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_suspendControlSession());
      case AppLifecycleState.resumed:
        unawaited(_resumeControlSession());
        break;
    }
  }

  /// 从后台恢复时重新开始安全倒计时，完成前不恢复控制输出。
  Future<void> _resumeControlSession() async {
    if (!_controlSessionStopped || !mounted) {
      return;
    }
    _controlSessionStopped = false;
    _getControlController().prepareControlSession();
    setState(() {
      _countdownValue = 3;
      _countdownCompleted = false;
    });
    _startCountdown();
  }

  /// 页面离开或应用不可见时停发控制帧，并阻止本页再次自动激活。
  Future<void> _suspendControlSession([ControlController? controller]) async {
    if (_controlSessionStopped) {
      return;
    }
    _controlSessionStopped = true;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownCompleted = false;
    final activeController = controller ?? _controlController;
    if (activeController == null) {
      return;
    }
    await activeController.suspendControlOutput();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _countdownTimer = null;
    final controlController = _controlController;
    final backgroundVideoController = _backgroundVideoController;
    _backgroundVideoController = null;
    _controlController = null;
    _presentationControlStateSubscription?.close();
    _presentationControlStateSubscription = null;
    _connectionSubscription?.close();
    _connectionSubscription = null;
    unawaited(_suspendControlSession(controlController));
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
    final connectionState = ref.watch(effectiveReceiverConnectionProvider);
    final connectedRssi = ref.watch(effectiveConnectedRssiProvider);
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
    final alertMessage = ref.watch(controlPageAlertMessageProvider);

    final connected = connectionState == ReceiverConnectionState.connected;
    final batteryStatus = ref.watch(receiverBatteryStatusProvider);
    final batteryLevel = connected ? (batteryStatus?.iconPercent ?? 0) : 0;
    final rssi = connected ? connectedRssi : null;

    final showThrottleTurnSignals = leftTurnActive || rightTurnActive;
    final gyroControlEnabled =
        controlState.gyroEnabled && settings.gyroMode != GyroMode.off;
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
                    lowLabel: compactDriveModeLabel(context, high: false),
                    highLabel: compactDriveModeLabel(context, high: true),
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
                      alertMessage: alertMessage,
                      battery: batteryLevel,
                      rssi: rssi,
                      onSettings: () {
                        Navigator.of(context).pushNamed(AppRoutes.settings);
                      },
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
                        if (settings.gyroMode != GyroMode.off) {
                          unawaited(_handleGyroToggle());
                        }
                      },
                      networkOn: gyroControlEnabled,
                      showThrottleTurnSignals: showThrottleTurnSignals,
                      leftTurnOn: leftTurnActive,
                      rightTurnOn: rightTurnActive,
                    ),
                    if (!connected) const SizedBox(height: 16),

                    const SizedBox(height: 52),

                    Expanded(
                      child: _ControlArea(
                        leftPadIsThrottle: leftPadIsThrottle,
                        handedness: settings.handedness,
                        controlMode: settings.controlMode,
                        gyroMode: settings.gyroMode,
                        gyroHandMode: settings.gyroHandMode,
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
          if (_countdownValue != null)
            Positioned.fill(
              child: AbsorbPointer(
                child: Center(
                  child: Text(
                    '$_countdownValue',
                    key: const ValueKey<String>('control-countdown'),
                    style: const TextStyle(
                      color: Color(0xFF00C6FF),
                      fontSize: 60,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      height: 1.171875,
                    ),
                  ),
                ),
              ),
            ),
          if (_countdownValue != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  key: const ValueKey<String>('control-countdown-back'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(width: 129, height: 49),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.alertMessage,
    required this.battery,
    required this.rssi,
    required this.onSettings,
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

  final String? alertMessage;
  final int battery;
  final int? rssi;
  final VoidCallback onSettings;
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
                  value: rssiToControlSignalPercent(rssi).toDouble(),
                  width: 29,
                  height: 16,
                ),
                const SizedBox(width: 16),
                BatteryWidget(value: battery.toDouble(), width: 29, height: 16),
              ],
            ),
            Expanded(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: Alignment.center,
                    child: alertMessage == null
                        ? const SizedBox.shrink()
                        : ControlStatusWarningText(message: alertMessage!),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _CircleIconBtn.svg(
                  assetPath: 'assets/icons/sync_arrows.svg',
                  active: directionOn,
                  onTap: onDirection,
                ),
                const SizedBox(width: 16),
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
                _ControlSettingsButton(onTap: onSettings),
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
                padding: const EdgeInsets.all(7),
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

class _ControlSettingsButton extends StatelessWidget {
  const _ControlSettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: SvgPicture.string(_settingsButtonSvg, fit: BoxFit.contain),
      ),
    );
  }
}

const _settingsButtonSvg =
    '''<svg xmlns="http://www.w3.org/2000/svg" width="72" height="72" viewBox="0 0 72 72" fill="none"><circle cx="36" cy="36" r="36" fill="#1B2D4D" fill-opacity="0.4"/><path fill-rule="evenodd" fill="url(#linear_border_126_1288_0)" d="M36 72C55.8823 72 72 55.8823 72 36C72 16.1177 55.8823 0 36 0C16.1177 0 0 16.1177 0 36C0 55.8823 16.1177 72 36 72ZM36 2C54.7777 2 70 17.2223 70 36C70 54.7777 54.7777 70 36 70C17.2223 70 2 54.7777 2 36C2 17.2223 17.2223 2 36 2Z"/><path d="M55.8665 32.8538C55.4661 31.6531 54.3982 30.8527 53.1301 30.8305H50.8609C50.6162 30.8305 50.505 30.7638 50.4383 30.5414C50.3938 30.3858 50.327 30.2301 50.2603 30.0745C50.0527 29.6002 50.1417 29.1703 50.5272 28.7849L51.7063 27.5842C52.8632 26.3835 52.8854 24.6492 51.7286 23.4263C50.683 22.3369 49.6374 21.2918 48.5473 20.2468C47.3237 19.0684 45.5884 19.0906 44.3648 20.2913L42.8521 21.8255C42.6741 22.0033 42.5183 22.0256 42.3181 21.9144C41.9399 21.7365 41.5617 21.5809 41.1613 21.4252V19.0461C41.1613 17.2451 39.8932 16 38.1135 16H33.8865C32.0845 16 30.8387 17.2451 30.8387 19.0461V21.0695C30.8387 21.3808 30.7497 21.5142 30.4605 21.5809C30.3493 21.6031 30.238 21.6476 30.1268 21.692C29.5929 21.8996 29.1183 21.8032 28.703 21.403L27.5017 20.2246C26.3671 19.1573 24.6318 19.1128 23.4972 20.1801C22.3626 21.2696 21.228 22.3813 20.1602 23.5153C19.0923 24.6492 19.1146 26.3835 20.2047 27.5175L21.8064 29.1184C21.9622 29.274 22.0289 29.4074 21.9177 29.6298C21.762 29.9188 21.6285 30.2301 21.5395 30.5192C21.4727 30.7638 21.317 30.8305 21.0945 30.8082H18.9143C17.2903 30.8082 16 32.0756 16 33.6987V38.2346C16 39.8577 17.3126 41.1028 18.9366 41.1251H21.4283C21.6285 41.5698 21.8064 41.9922 21.9844 42.4369C22.0289 42.5258 21.9399 42.7037 21.8509 42.7927L20.3382 44.3268C19.1146 45.572 19.0923 47.3285 20.3382 48.5959L23.4082 51.6642C24.6541 52.8871 26.4116 52.8649 27.6351 51.6642L29.1479 50.1523C29.3037 49.9744 29.4371 49.93 29.6596 50.0634C29.8153 50.1523 29.9933 50.219 30.1491 50.2857C30.6088 50.4785 30.8387 50.8267 30.8387 51.3307V53.0428C30.8387 54.488 31.7508 55.5998 33.1746 55.9333C33.2414 55.9333 33.2859 55.9778 33.3526 56H38.6696C39.337 55.8221 39.9599 55.5553 40.4494 54.9994C40.9166 54.4658 41.1835 53.8432 41.1835 53.1095V50.7971C41.1835 50.597 41.2503 50.4858 41.4282 50.4191C41.6507 50.3524 41.8732 50.2635 42.0734 50.1745C42.4589 50.0116 42.8002 50.0783 43.0968 50.3746L44.3871 51.6642C45.5884 52.8204 47.3237 52.8649 48.525 51.7087L51.7286 48.5069C52.8854 47.3063 52.8632 45.572 51.6841 44.3713L50.1713 42.8594C49.9711 42.6815 49.9488 42.5036 50.0823 42.2813C50.1713 42.1479 50.2158 41.9922 50.2825 41.8588C50.4754 41.3845 50.8387 41.1473 51.3726 41.1473H53.0189C54.465 41.1473 55.5773 40.2801 55.9332 38.8571C55.9332 38.7904 55.9777 38.7015 56 38.6348V33.3207C55.9555 33.1651 55.911 33.0094 55.8443 32.8316L55.8665 32.8538ZM42.1846 36.0111C42.1846 39.413 39.426 42.1701 36.0222 42.1923C32.574 42.1923 29.7931 39.4352 29.7931 36.0111C29.7931 32.587 32.5295 29.8299 35.9555 29.8299C39.4038 29.8299 42.1624 32.5648 42.1624 36.0333L42.1846 36.0111Z" fill="url(#linear_fill_126_1291)"/><defs><linearGradient id="linear_border_126_1288_0" x1="36" y1="72" x2="36" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#7EA2CF" stop-opacity="0.4"/><stop offset="0.2807" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="0.5394" stop-color="#7DA2CE"/><stop offset="0.7815" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="1" stop-color="#7DA2CE" stop-opacity="0.4"/></linearGradient><linearGradient id="linear_fill_126_1291" x1="36" y1="16" x2="36" y2="56" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#EDF5FF"/><stop offset="1" stop-color="#92C3FF"/></linearGradient></defs></svg>''';

// 涓笅閮ㄦ帶鍒跺尯鍩?
class _ControlArea extends StatelessWidget {
  static const _verticalControlLeft = 40.0;
  static const _horizontalControlBottom = 20.0;
  static const _floatingVerticalZoneWidth = 160.0;
  static const _floatingVerticalZoneHeight = 260.0;
  static const _floatingHorizontalZoneWidth = 260.0;
  static const _floatingHorizontalZoneHeight = 100.0;
  static const _trimBottomClearance = 48.0;
  static const _trimRightClearance = 42.0;
  static const _steeringTrimWidth = 204.0;
  static const _throttleTrimHeight = 200.0;
  static const _gyroDirectionVerticalControlHeight = 200.0;

  const _ControlArea({
    required this.leftPadIsThrottle,
    required this.handedness,
    required this.controlMode,
    required this.gyroMode,
    required this.gyroHandMode,
    required this.controlState,
    required this.controlController,
    required this.inputLocked,
  });

  final bool leftPadIsThrottle;
  final Handedness handedness;
  final ControlMode controlMode;
  final GyroMode gyroMode;
  final GyroHandMode gyroHandMode;
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

  /// 构建固定在左下角的水平转向微调条。
  Widget _buildSteeringTrim() {
    return RCControllSider(
      key: const ValueKey<String>('control-steering-trim'),
      direction: RCControllSiderDirection.horizontal,
      initialValue: controlState.trim / 60,
      step: 0.02,
      enabled: controlState.sliderButtonsVisible,
      showButtons: controlState.sliderButtonsVisible,
      onChanged: (value) {
        unawaited(controlController.setSteeringTrim((value * 60).round()));
      },
    );
  }

  /// 构建固定在最右侧的竖向油门微调条。
  Widget _buildThrottleTrim() {
    return RCControllSider(
      key: const ValueKey<String>('control-throttle-trim'),
      direction: RCControllSiderDirection.vertical,
      initialValue: controlState.throttleTrim / 60,
      step: 0.02,
      trackMain: 160,
      enabled: controlState.sliderButtonsVisible,
      showButtons: controlState.sliderButtonsVisible,
      lockSignUntilRelease: true,
      onChanged: (value) {
        unawaited(controlController.setThrottleTrim((value * 60).round()));
      },
    );
  }

  /// 构建竖向主控；微调由外层固定布局统一承载，避免重复显示。
  Widget _buildVerticalArea({Widget? controlOverride}) {
    return controlOverride ?? _buildVerticalStick();
  }

  /// 构建方向体感模式下的竖向油门控件，为上下按钮预留足够间距。
  Widget _buildGyroDirectionVerticalArea() {
    if (_useFloatingStickStyle) {
      return VerticalFloatingControlZone(
        width: _floatingVerticalZoneWidth,
        height: _floatingVerticalZoneHeight,
        controlHeight: _gyroDirectionVerticalControlHeight,
        onChanged: (value) {
          unawaited(controlController.setThrottle(value));
        },
      );
    }

    return Control(
      direction: ControlSliderDirection.vertical,
      height: _gyroDirectionVerticalControlHeight,
      onChanged: (value) {
        controlController.setThrottle(value / 100);
      },
    );
  }

  /// 构建横向主控；微调由外层固定布局统一承载，避免重复显示。
  Widget _buildHorizontalArea({Widget? controlOverride}) {
    return controlOverride ?? _buildHorizontalStick();
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

  /// 将左侧操控的中心线对齐到固定水平微调，主控始终位于微调上方。
  Widget _buildLeftAnchoredControl(Widget control) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _trimBottomClearance),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: SizedBox(
          width: _steeringTrimWidth,
          child: Align(alignment: Alignment.bottomCenter, child: control),
        ),
      ),
    );
  }

  /// 将右侧操控放入与竖向微调等高的参考区，使两者中心 Y 轴对齐。
  Widget _buildRightAnchoredControl(Widget control) {
    return Align(
      alignment: Alignment.bottomRight,
      child: SizedBox(
        height: _throttleTrimHeight,
        child: Padding(
          padding: const EdgeInsets.only(right: _trimRightClearance),
          child: OverflowBox(
            alignment: Alignment.centerRight,
            minHeight: 0,
            maxHeight: double.infinity,
            child: control,
          ),
        ),
      ),
    );
  }

  /// 使用固定微调作为左右锚点承载主控，双手模式不再使用屏幕居中布局。
  Widget _buildAnchoredControlLayout({
    Widget? leftControl,
    Widget? rightControl,
  }) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (leftControl != null) _buildLeftAnchoredControl(leftControl),
        if (rightControl != null) _buildRightAnchoredControl(rightControl),
      ],
    );
  }

  /// 为所有控制布局固定左右微调位置，主控仅根据对应锚点变化。
  Widget _buildMainControlArea(Widget child) {
    return AbsorbPointer(
      absorbing: inputLocked,
      child: Padding(
        padding: const EdgeInsets.only(
          left: _verticalControlLeft,
          right: 16,
          bottom: _horizontalControlBottom,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Align(alignment: Alignment.bottomLeft, child: _buildSteeringTrim()),
            Align(
              alignment: Alignment.bottomRight,
              child: _buildThrottleTrim(),
            ),
          ],
        ),
      ),
    );
  }

  /// 体感控制方向时，按体感手型展示剩余的油门触控区域。
  Widget _buildGyroDirectionArea() {
    switch (gyroHandMode) {
      case GyroHandMode.left:
        return _buildMainControlArea(
          _buildAnchoredControlLayout(
            leftControl: _buildGyroDirectionVerticalArea(),
          ),
        );
      case GyroHandMode.right:
        return _buildMainControlArea(
          _buildAnchoredControlLayout(
            rightControl: _buildGyroDirectionVerticalArea(),
          ),
        );
      case GyroHandMode.dual:
        return _buildMainControlArea(
          _buildAnchoredControlLayout(
            leftControl: _buildFixedDirectionalThrottleStick(
              positiveThrottle: false,
              showArrowHint: true,
            ),
            rightControl: _buildFixedDirectionalThrottleStick(
              positiveThrottle: true,
              showArrowHint: true,
            ),
          ),
        );
    }
  }

  /// 体感控制油门时，按体感手型展示剩余的方向触控区域。
  Widget _buildGyroThrottleArea() {
    switch (gyroHandMode) {
      case GyroHandMode.left:
        return _buildMainControlArea(
          _buildAnchoredControlLayout(leftControl: _buildHorizontalArea()),
        );
      case GyroHandMode.right:
        return _buildMainControlArea(
          _buildAnchoredControlLayout(rightControl: _buildHorizontalArea()),
        );
      case GyroHandMode.dual:
        return _buildMainControlArea(
          _buildAnchoredControlLayout(
            leftControl: DirectionalSteeringButton(
              direction: -1,
              onChanged: controlController.setSteering,
            ),
            rightControl: DirectionalSteeringButton(
              direction: 1,
              onChanged: controlController.setSteering,
            ),
          ),
        );
    }
  }

  /// 体感关闭时沿用基本设置的四种手型布局。
  Widget _buildManualControlArea() {
    final singleHandRight = handedness == Handedness.singleRight;
    final singleHandLeft = handedness == Handedness.singleLeft;
    if (singleHandRight || singleHandLeft) {
      return _buildMainControlArea(
        Padding(
          padding: EdgeInsets.only(
            right: singleHandRight ? _trimRightClearance : 0,
            bottom: _trimBottomClearance,
          ),
          child: singleHandRight
              ? SingleHandRightControl(
                  steeringTrim: controlState.trim,
                  throttleTrim: controlState.throttleTrim,
                  showTrimButtons: controlState.sliderButtonsVisible,
                  showTrims: false,
                  onControlChanged: (value) {
                    // 双轴值复用原有主通道入口，确保发送链路保持一致。
                    unawaited(controlController.setSteering(value.steering));
                    unawaited(controlController.setThrottle(value.throttle));
                  },
                  onSteeringTrimChanged: (value) {
                    unawaited(controlController.setSteeringTrim(value));
                  },
                  onThrottleTrimChanged: (value) {
                    unawaited(controlController.setThrottleTrim(value));
                  },
                )
              : SingleHandLeftControl(
                  steeringTrim: controlState.trim,
                  throttleTrim: controlState.throttleTrim,
                  showTrimButtons: controlState.sliderButtonsVisible,
                  showTrims: false,
                  onControlChanged: (value) {
                    // 双轴值复用原有主通道入口，确保发送链路保持一致。
                    unawaited(controlController.setSteering(value.steering));
                    unawaited(controlController.setThrottle(value.throttle));
                  },
                  onSteeringTrimChanged: (value) {
                    unawaited(controlController.setSteeringTrim(value));
                  },
                  onThrottleTrimChanged: (value) {
                    unawaited(controlController.setThrottleTrim(value));
                  },
                ),
        ),
      );
    }

    final leftArea = leftPadIsThrottle
        ? _buildVerticalArea()
        : _buildHorizontalArea();
    final rightArea = leftPadIsThrottle
        ? _buildHorizontalArea()
        : _buildVerticalArea();
    return _buildMainControlArea(
      Padding(
        padding: const EdgeInsets.only(
          right: _trimRightClearance,
          bottom: _trimBottomClearance,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [leftArea, rightArea],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (gyroMode) {
      GyroMode.off => _buildManualControlArea(),
      GyroMode.directionOnly => _buildGyroDirectionArea(),
      GyroMode.throttleOnly => _buildGyroThrottleArea(),
      GyroMode.all => _buildMainControlArea(const SizedBox.shrink()),
    };
  }
}

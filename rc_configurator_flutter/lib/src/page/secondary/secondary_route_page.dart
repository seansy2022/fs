import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rc_ui/rc_ui.dart';
import '../../provider/app_state_models.dart';
import '../../provider/app_state_provider.dart';
import '../../provider/dashboard_provider.dart';
import '../../types.dart';
import 'channel_reverse.dart';
import 'channel_travel.dart';
import 'control_mapping.dart';
import 'curve.dart';
import 'dual_rate.dart';
import 'failsafe.dart';
import 'mixing.dart';
import 'model_selection.dart';
import 'radio_settings.dart';
import 'sub_trim.dart';

class SecondaryRoutePage extends ConsumerStatefulWidget {
  const SecondaryRoutePage({super.key, required this.screen});
  final Screen screen;

  @override
  ConsumerState<SecondaryRoutePage> createState() => _SecondaryRoutePageState();
}

class _SecondaryRoutePageState extends ConsumerState<SecondaryRoutePage> {
  static const _subTrimRepeatThreshold = Duration(milliseconds: 140);
  static const _subTrimLockReleaseDelay = Duration(milliseconds: 220);
  late final RcAppController _appController;
  bool _screenRefreshInFlight = false;
  bool _pendingSyncAfterConnect = false;
  String? _subTrimRapidChannelId;
  String? _subTrimLockedChannelId;
  DateTime? _subTrimLastAt;
  Timer? _subTrimLockReleaseTimer;

  @override
  void initState() {
    super.initState();
    _appController = ref.read(rcAppStateProvider.notifier);
    _handleControlMappingEnter(widget.screen);
    _syncScreenRefresh(widget.screen);
  }

  @override
  void didUpdateWidget(covariant SecondaryRoutePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screen != widget.screen) {
      _handleControlMappingLeave(oldWidget.screen);
      _handleControlMappingEnter(widget.screen);
      _syncScreenRefresh(widget.screen);
    }
  }

  @override
  void dispose() {
    _handleControlMappingLeave(widget.screen);
    _subTrimLockReleaseTimer?.cancel();
    super.dispose();
  }

  void _handleControlMappingEnter(Screen screen) {
    if (screen != Screen.controlMapping) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.screen != Screen.controlMapping) return;
      _appController.enterControlMappingPage();
      _syncScreenRefresh(widget.screen);
    });
  }

  void _handleControlMappingLeave(Screen screen) {
    if (screen != Screen.controlMapping) return;
    _appController.leaveControlMappingPage();
  }

  void _syncScreenRefresh(Screen screen) {
    if (screen == Screen.controlMapping) return;
    unawaited(_syncScreenConfig());
  }

  Future<void> _syncScreenConfig({bool retry = false}) async {
    if (!mounted || _screenRefreshInFlight) return;
    final connected = ref.read(
      rcAppStateProvider.select((state) => state.bluetooth.isConnected),
    );
    if (!connected) {
      _pendingSyncAfterConnect = true;
      return;
    }
    _screenRefreshInFlight = true;
    var shouldRetry = false;
    try {
      final result = await ref
          .read(rcAppStateProvider.notifier)
          .refreshForScreenWithStatus(widget.screen);
      _pendingSyncAfterConnect = result == ScreenRefreshResult.needConnection;
      shouldRetry = result == ScreenRefreshResult.needSession && !retry;
    } finally {
      _screenRefreshInFlight = false;
    }
    if (!shouldRetry || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _syncScreenConfig(retry: true);
  }

  Future<void> _resetScreenDefaults({bool resetAllMixingModes = false}) async {
    if (!mounted || _screenRefreshInFlight) return;
    final confirmed = await AlertModelWidget.show(
      context,
      title: '确认复位出场默认设置?',
      cancelText: '取消',
      confirmText: '确认',
    );
    if (!mounted || confirmed != true) return;
    _screenRefreshInFlight = true;
    try {
      final sent = await ref
          .read(rcAppStateProvider.notifier)
          .resetDefaultsForScreen(
            widget.screen,
            resetAllMixingModes: resetAllMixingModes,
          );
      if (!mounted || sent) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('已恢复默认值，当前未连接设备，未发送到设备')),
      );
    } finally {
      _screenRefreshInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      rcAppStateProvider.select((state) => state.bluetooth.isConnected),
      (previous, next) {
        if (!mounted) return;
        if (next != true || previous == true) return;
        if (!_pendingSyncAfterConnect) return;
        unawaited(_syncScreenConfig());
      },
    );
    ref.listen<String?>(
      rcAppStateProvider.select((state) => state.bluetooth.errorMessage),
      (previous, next) {
        if (!mounted) return;
        if (next == null || next.isEmpty || next == previous) return;
        if (!next.contains('读取设备数据失败')) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(next)));
      },
    );
    final channels = ref.watch(channelsProvider);
    final models = ref.watch(modelsProvider);
    final radioSettings = ref.watch(radioSettingsProvider);
    final mixingSettings = ref.watch(mixingSettingsProvider);
    final protocol = ref.watch(rcAppStateProvider.select((s) => s.protocol));
    final activeModel = ref.watch(activeModelNameProvider);
    return TechShell(
      child: Column(
        children: [
          RepaintBoundary(
            child: TopAppBar(
              title: _titleFor(widget.screen),
              onBack: () => Navigator.of(context).pop(),
              onRefresh: () => unawaited(
                _resetScreenDefaults(
                  resetAllMixingModes: widget.screen == Screen.mixing,
                ),
              ),
            ),
          ),
          Expanded(
            child: switch (widget.screen) {
              Screen.channels => ChannelTravel(
                channels: channels,
                onUpdateChannel: _updateTravelChannel,
              ),
              Screen.reverse => ChannelReverse(
                channels: channels,
                onUpdateChannel: _updateReverseChannel,
              ),
              Screen.subTrim => SubTrim(
                channels: channels,
                onUpdateChannel: _updateSubTrimChannel,
              ),
              Screen.dualRate => DualRate(
                channels: channels,
                activeModel: activeModel,
                onUpdateDualRate: _updateDualRate,
              ),
              Screen.curve => const CurvePage(),
              Screen.controlMapping => const ControlMapping(),
              Screen.modelSelection => ModelSelection(
                models: models,
                onSelectModel: _selectModel,
                onRenameModel: _renameModel,
              ),
              Screen.failsafe => Failsafe(
                channels: channels,
                onUpdateChannel: _updateFailsafeChannel,
              ),
              Screen.radioSettings => RadioSettingsView(
                settings: radioSettings,
                onUpdateSettings: _updateRadioSettings,
              ),
              Screen.mixing => Mixing(
                settings: mixingSettings,
                protocol: protocol,
                channels: channels,
                onUpdateSettings: _updateMixingSettings,
                onReset: () =>
                    unawaited(_resetScreenDefaults(resetAllMixingModes: false)),
              ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }

  void _updateTravelChannel(String id, ChannelState next) {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(ChannelTravelUpdatedIntent(id: id, next: next));
  }

  void _updateReverseChannel(String id, ChannelState next) {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(ChannelReverseUpdatedIntent(id: id, next: next));
  }

  void _updateSubTrimChannel(String id, ChannelState next) {
    if (!_allowSubTrimChannelUpdate(id)) return;
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(SubTrimUpdatedIntent(id: id, next: next));
  }

  bool _allowSubTrimChannelUpdate(String id) {
    final locked = _subTrimLockedChannelId;
    if (locked != null && locked != id) return false;
    final now = DateTime.now();
    final lastAt = _subTrimLastAt;
    final rapid =
        _subTrimRapidChannelId == id &&
        lastAt != null &&
        now.difference(lastAt) <= _subTrimRepeatThreshold;
    if (rapid) _subTrimLockedChannelId = id;
    _subTrimRapidChannelId = id;
    _subTrimLastAt = now;
    _subTrimLockReleaseTimer?.cancel();
    _subTrimLockReleaseTimer = Timer(_subTrimLockReleaseDelay, () {
      _subTrimRapidChannelId = null;
      _subTrimLockedChannelId = null;
      _subTrimLastAt = null;
      _subTrimLockReleaseTimer = null;
    });
    return true;
  }

  void _updateFailsafeChannel(String id, ChannelState next) {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(FailsafeUpdatedIntent(id: id, next: next));
  }

  void _updateDualRate(String id, ChannelState next) {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(DualRateUpdatedIntent(id: id, next: next));
  }

  void _selectModel(String id) {
    ref.read(rcAppStateProvider.notifier).dispatch(ModelSelectedIntent(id));
  }

  void _renameModel(String id, String name) {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(ModelRenamedIntent(id: id, name: name));
  }

  void _updateRadioSettings(RadioSettings next) {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(RadioSettingsUpdatedIntent(next));
  }

  void _updateMixingSettings(MixingSettings next) {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(MixingSettingsUpdatedIntent(next));
  }
}

String _titleFor(Screen screen) {
  switch (screen) {
    case Screen.channels:
      return '通道行程';
    case Screen.reverse:
      return '通道反向';
    case Screen.subTrim:
      return '中立微调';
    case Screen.dualRate:
      return '双比率';
    case Screen.curve:
      return '曲线设置';
    case Screen.controlMapping:
      return '控件分配';
    case Screen.modelSelection:
      return '模型选择';
    case Screen.failsafe:
      return '失控保护';
    case Screen.radioSettings:
      return '遥控器设置';
    case Screen.mixing:
      return '混控';
    case Screen.bluetooth:
      return '蓝牙连接';
    case Screen.functions:
      return '菜单';
    case Screen.dashboard:
      return '';
  }
}

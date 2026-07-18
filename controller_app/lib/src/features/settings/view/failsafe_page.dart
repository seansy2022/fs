import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../../../provider/bluetooth_domain_provider.dart';
import '../../../provider/global_reconnect_provider.dart';
import '../models/app_settings_state.dart';
import '../widgets/numeric_input_dialog.dart';
import '../widgets/settings_workspace.dart';

class FailsafePage extends ConsumerStatefulWidget {
  const FailsafePage({super.key});

  @override
  ConsumerState<FailsafePage> createState() => _FailsafePageState();
}

class _FailsafePageState extends ConsumerState<FailsafePage> {
  @override
  Widget build(BuildContext context) {
    return SettingsWorkspace(
      activeRoute: AppRoutes.failsafe,
      onBack: () => Navigator.of(context).pop(),
      content: const FailsafeContent(),
    );
  }
}

class FailsafeContent extends ConsumerStatefulWidget {
  const FailsafeContent({super.key});

  @override
  ConsumerState<FailsafeContent> createState() => _FailsafeContentState();
}

class _FailsafeContentState extends ConsumerState<FailsafeContent> {
  int _steeringUs = 1500;
  int _throttleUs = 1500;
  int _ch3Us = 1500;
  int _ch4Us = 1500;
  bool _steeringHold = true;
  bool _throttleHold = true;
  bool _ch3Hold = true;
  bool _ch4Hold = true;
  bool _testing = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadConfig());
  }

  @override
  void dispose() {
    if (_testing) {
      unawaited(_restoreControl());
    }
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _loading = true);
    try {
      final ready = await _ensureReceiverReady();
      if (!ready) {
        return;
      }
      final config = await ref.read(receiverRepositoryProvider).readFailsafe();
      if (!mounted) return;
      setState(() {
        _steeringUs = config.steeringUs;
        _throttleUs = config.throttleUs;
        _ch3Us = config.ch3Us;
        _ch4Us = config.ch4Us;
        _steeringHold = config.steeringHold;
        _throttleHold = config.throttleHold;
        _ch3Hold = config.ch3Hold;
        _ch4Hold = config.ch4Hold;
      });
    } catch (_) {
      // Use defaults
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// 断开蓝牙连接，触发接收机已保存的失控保护配置。
  Future<void> _startTest() async {
    try {
      setState(() => _testing = true);
      final bluetooth = ref.read(bluetoothDomainControllerProvider.notifier);
      // 停止重连和扫描任务，再使用受抑制的主动断开避免自动回连。
      await ref.read(globalReconnectControllerProvider.notifier).cancel();
      await bluetooth.cancelPendingAutoReconnect();
      await bluetooth.ensureScanStopped();
      await ref.read(receiverRepositoryProvider).stopControlLoop();
      final disconnected = await bluetooth.disconnect();
      if (!disconnected) {
        throw StateError('Bluetooth disconnect failed.');
      }
      if (mounted) {
        await AlertIconWidget.show(
          context,
          title: '测试模式',
          message: '蓝牙已断开，接收机将进入失控保护状态。\n点击“恢复”后将扫描并重新连接蓝牙。',
          confirmText: '恢复',
        );
        await _restoreControl();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  /// 扫描并连接最近使用的接收机，连接成功后恢复控制心跳。
  Future<void> _restoreControl() async {
    try {
      if (!mounted) return;
      final connected = await ref
          .read(bluetoothDomainControllerProvider.notifier)
          .autoReconnectLastDevice();
      if (!connected) {
        throw StateError('Bluetooth reconnect failed.');
      }
      await ref.read(receiverRepositoryProvider).startControlLoop();
      if (mounted) {
        setState(() => _testing = false);
      }
    } catch (_) {
      if (mounted) {
        await AlertIconWidget.show(
          context,
          title: '恢复失败',
          message: '未能重新连接蓝牙，请确认接收机已上电后再次点击 TEST 恢复。',
          confirmText: '知道了',
        );
      }
    }
  }

  /// 组装失控保护全量写入参数；保持状态由 Data[23] 位标志表达。
  ReceiverFailsafeConfig get _currentConfig {
    final channels = ref.read(appSettingsProvider).channels;
    return ReceiverFailsafeConfig(
      throttleUs: _throttleUs,
      steeringUs: _steeringUs,
      throttleHold: _throttleHold,
      steeringHold: _steeringHold,
      // 辅助通道被禁用时，强制写入中位值，避免保留旧的失控保护输出。
      ch3Us: _isAuxChannelDisabled(channels, 2) ? 1500 : _ch3Us,
      ch4Us: _isAuxChannelDisabled(channels, 3) ? 1500 : _ch4Us,
      ch3Hold: _isAuxChannelDisabled(channels, 2) ? false : _ch3Hold,
      ch4Hold: _isAuxChannelDisabled(channels, 3) ? false : _ch4Hold,
    );
  }

  Future<bool> _ensureReceiverReady() async {
    final repository = ref.read(receiverRepositoryProvider);
    if (repository.receiverInfo != null) {
      return true;
    }
    try {
      await repository.readReceiverInfo();
      return true;
    } catch (_) {
      if (mounted) {
        await AlertIconWidget.show(
          context,
          title: '设备未就绪',
          message: '暂时无法读取设备信息，失控保护参数还不能读取或写入，请稍后重试。',
          confirmText: '知道了',
        );
      }
      return false;
    }
  }

  Future<void> _saveConfig() async {
    final ready = await _ensureReceiverReady();
    if (!ready) {
      return;
    }
    await ref.read(receiverRepositoryProvider).writeFailsafe(_currentConfig);
  }

  Future<void> _setSteeringHold(bool hold) async {
    final previous = _steeringHold;
    setState(() => _steeringHold = hold);
    try {
      await _saveConfig();
    } catch (_) {
      if (mounted) {
        setState(() => _steeringHold = previous);
      }
    }
  }

  Future<void> _setThrottleHold(bool hold) async {
    final previous = _throttleHold;
    setState(() => _throttleHold = hold);
    try {
      await _saveConfig();
    } catch (_) {
      if (mounted) {
        setState(() => _throttleHold = previous);
      }
    }
  }

  Future<void> _setSteeringValue(int valueUs) async {
    final previous = _steeringUs;
    setState(() => _steeringUs = valueUs);
    try {
      await _saveConfig();
    } catch (_) {
      if (mounted) {
        setState(() => _steeringUs = previous);
      }
    }
  }

  Future<void> _setThrottleValue(int valueUs) async {
    final previous = _throttleUs;
    setState(() => _throttleUs = valueUs);
    try {
      await _saveConfig();
    } catch (_) {
      if (mounted) {
        setState(() => _throttleUs = previous);
      }
    }
  }

  /// 切换 CH3 的保持状态；失败时恢复页面中的原有选择。
  Future<void> _setCh3Hold(bool hold) async {
    final previous = _ch3Hold;
    setState(() => _ch3Hold = hold);
    try {
      await _saveConfig();
    } catch (_) {
      if (mounted) {
        setState(() => _ch3Hold = previous);
      }
    }
  }

  /// 切换 CH4 的保持状态；失败时恢复页面中的原有选择。
  Future<void> _setCh4Hold(bool hold) async {
    final previous = _ch4Hold;
    setState(() => _ch4Hold = hold);
    try {
      await _saveConfig();
    } catch (_) {
      if (mounted) {
        setState(() => _ch4Hold = previous);
      }
    }
  }

  /// 更新 CH3 固定值；写入失败后回退为修改前的数值。
  Future<void> _setCh3Value(int valueUs) async {
    final previous = _ch3Us;
    setState(() => _ch3Us = valueUs);
    try {
      await _saveConfig();
    } catch (_) {
      if (mounted) {
        setState(() => _ch3Us = previous);
      }
    }
  }

  /// 更新 CH4 固定值；写入失败后回退为修改前的数值。
  Future<void> _setCh4Value(int valueUs) async {
    final previous = _ch4Us;
    setState(() => _ch4Us = valueUs);
    try {
      await _saveConfig();
    } catch (_) {
      if (mounted) {
        setState(() => _ch4Us = previous);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(appSettingsProvider).channels;
    final ch3Disabled = _isAuxChannelDisabled(channels, 2);
    final ch4Disabled = _isAuxChannelDisabled(channels, 3);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _FailsafeChannelStrip(
                  title: '方向',
                  valueUs: _steeringUs,
                  hold: _steeringHold,
                  onHoldChanged: (v) => unawaited(_setSteeringHold(v)),
                  onValueChanged: (v) => unawaited(_setSteeringValue(v)),
                  enabled: !_loading,
                ),
                const SizedBox(height: 8),
                _FailsafeChannelStrip(
                  title: '油门',
                  valueUs: _throttleUs,
                  hold: _throttleHold,
                  onHoldChanged: (v) => unawaited(_setThrottleHold(v)),
                  onValueChanged: (v) => unawaited(_setThrottleValue(v)),
                  enabled: !_loading,
                ),
                const SizedBox(height: 8),
                _FailsafeChannelStrip(
                  title: 'CH3',
                  valueUs: _ch3Us,
                  hold: _ch3Hold,
                  disabled: ch3Disabled,
                  onHoldChanged: (v) => unawaited(_setCh3Hold(v)),
                  onValueChanged: (v) => unawaited(_setCh3Value(v)),
                  enabled: !_loading,
                ),
                const SizedBox(height: 8),
                _FailsafeChannelStrip(
                  title: 'CH4',
                  valueUs: _ch4Us,
                  hold: _ch4Hold,
                  disabled: ch4Disabled,
                  onHoldChanged: (v) => unawaited(_setCh4Hold(v)),
                  onValueChanged: (v) => unawaited(_setCh4Value(v)),
                  enabled: !_loading,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: SizedBox(
            width: 174,
            height: 44,
            child: PrimaryButton(
              text: 'TEST',
              type: PrimaryButtonType.primary,
              enabled: true,
              padding: EdgeInsets.zero,
              onTap: _testing ? _restoreControl : _startTest,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

/// 判断 CH3/CH4 是否在通道设置中被明确禁用。
bool _isAuxChannelDisabled(List<ChannelSetting> channels, int channelIndex) {
  return channelIndex >= channels.length ||
      channels[channelIndex].controlType == AuxControlType.disabled;
}

class _FailsafeChannelStrip extends StatefulWidget {
  const _FailsafeChannelStrip({
    required this.title,
    required this.valueUs,
    required this.hold,
    required this.onHoldChanged,
    required this.onValueChanged,
    required this.enabled,
    this.disabled = false,
  });

  final String title;
  final int valueUs;
  final bool hold;
  final ValueChanged<bool> onHoldChanged;
  final ValueChanged<int> onValueChanged;
  final bool enabled;
  final bool disabled;

  @override
  State<_FailsafeChannelStrip> createState() => _FailsafeChannelStripState();
}

class _FailsafeChannelStripState extends State<_FailsafeChannelStrip> {
  @override
  Widget build(BuildContext context) {
    final showValueInput = !widget.hold || widget.disabled;
    final valueUs = widget.disabled ? 1500 : widget.valueUs;
    final canEdit = widget.enabled && !widget.disabled;
    return SettingsStrip(
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              widget.title,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
            ),
          ),
          const Spacer(),
          if (showValueInput) ...[
            Opacity(
              opacity: widget.disabled ? 0.4 : 1,
              child: ItemButton(
                key: ValueKey<String>('failsafe-${widget.title}-value'),
                text: '$valueUs',
                selected: true,
                fontSize: 14,
                width: 88,
                height: 28,
                onTap: canEdit ? () => _editValue(context) : null,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Opacity(
            opacity: widget.disabled ? 0.4 : 1,
            child: ItemButton(
              key: ValueKey<String>('failsafe-${widget.title}-mode'),
              text: widget.disabled ? '禁用' : (widget.hold ? '保持' : '固定值'),
              selected: true,
              fontSize: 14,
              width: 74,
              height: 28,
              onTap: canEdit ? () => widget.onHoldChanged(!widget.hold) : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editValue(BuildContext context) async {
    final raw = await NumericInputDialog.show(
      context,
      title: '固定值',
      initialValue: widget.valueUs.toString(),
      unit: 'us',
      allowDecimal: false,
      maxAbsValue: 2100,
      maxLength: 4,
    );
    final parsed = int.tryParse(raw?.trim() ?? '');
    if (parsed == null) return;
    // 失控保护四路固定值统一限制为 900–2100 us。
    widget.onValueChanged(parsed.clamp(900, 2100));
  }
}

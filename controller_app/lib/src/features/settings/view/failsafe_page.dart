import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
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
  bool _steeringHold = true;
  bool _throttleHold = true;
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
        _steeringHold = config.steeringHold;
        _throttleHold = config.throttleHold;
      });
    } catch (_) {
      // Use defaults
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startTest() async {
    try {
      setState(() => _testing = true);
      await ref.read(receiverRepositoryProvider).stopControlLoop();
      if (mounted) {
        await AlertIconWidget.show(
          context,
          title: '测试模式',
          message: '已断开控制信号，接收机将进入失控保护状态。\n点击"恢复"按钮恢复控制。',
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

  Future<void> _restoreControl() async {
    try {
      if (!mounted) return;
      setState(() => _testing = false);
      await ref.read(receiverRepositoryProvider).startControlLoop();
    } catch (_) {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  ReceiverFailsafeConfig get _currentConfig => ReceiverFailsafeConfig(
    throttleUs: _throttleHold ? 0 : _throttleUs,
    steeringUs: _steeringHold ? 0 : _steeringUs,
  );

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: constraints.maxHeight,
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
            const Spacer(),
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
        ),
      ),
    );
  }
}

class _FailsafeChannelStrip extends StatefulWidget {
  const _FailsafeChannelStrip({
    required this.title,
    required this.valueUs,
    required this.hold,
    required this.onHoldChanged,
    required this.onValueChanged,
    required this.enabled,
  });

  final String title;
  final int valueUs;
  final bool hold;
  final ValueChanged<bool> onHoldChanged;
  final ValueChanged<int> onValueChanged;
  final bool enabled;

  @override
  State<_FailsafeChannelStrip> createState() => _FailsafeChannelStripState();
}

class _FailsafeChannelStripState extends State<_FailsafeChannelStrip> {
  @override
  Widget build(BuildContext context) {
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
          if (!widget.hold) ...[
            ItemButton(
              text: '${widget.valueUs}',
              selected: true,
              fontSize: 14,
              width: 88,
              height: 28,
              onTap: widget.enabled ? () => _editValue(context) : null,
            ),
            const SizedBox(width: 12),
          ],
          ItemButton(
            text: widget.hold ? '保持' : '固定值',
            selected: true,
            fontSize: 14,
            width: 74,
            height: 28,
            onTap: widget.enabled
                ? () => widget.onHoldChanged(!widget.hold)
                : null,
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
      maxLength: 4,
    );
    final parsed = int.tryParse(raw?.trim() ?? '');
    if (parsed == null) return;
    widget.onValueChanged(parsed.clamp(1000, 2000));
  }
}

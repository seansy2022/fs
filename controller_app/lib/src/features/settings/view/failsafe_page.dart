import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    try {
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
              onHoldChanged: (v) => setState(() => _steeringHold = v),
              onValueChanged: (v) => setState(() => _steeringUs = v),
              enabled: true,
            ),
            const SizedBox(height: 8),
            _FailsafeChannelStrip(
              title: '油门',
              valueUs: _throttleUs,
              hold: _throttleHold,
              onHoldChanged: (v) => setState(() => _throttleHold = v),
              onValueChanged: (v) => setState(() => _throttleUs = v),
              enabled: true,
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

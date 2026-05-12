import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
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
    return Column(
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
        const SizedBox(height: 8),
        // Test button
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
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FailsafeChannelStrip extends StatefulWidget {
  const _FailsafeChannelStrip({
    super.key,
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
            GestureDetector(
              onTap: widget.enabled ? () => _editValue(context) : null,
              child: Container(
                width: 88,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x661B2D4D),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF0072FF),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '${widget.valueUs}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: AppFonts.w700,
                  ),
                ),
              ),
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

  void _editValue(BuildContext context) {
    final controller = TextEditingController(text: widget.valueUs.toString());
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 220,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '输入数值',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: AppFonts.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: AppFonts.w700,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  PrimaryButton(
                    text: '取消',
                    width: 80,
                    type: PrimaryButtonType.normal,
                    onTap: () => Navigator.of(ctx).pop(),
                  ),
                  PrimaryButton(
                    text: '确定',
                    width: 80,
                    onTap: () {
                      final parsed =
                          int.tryParse(controller.text.trim()) ?? 1500;
                      widget.onValueChanged(parsed.clamp(1000, 2000));
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

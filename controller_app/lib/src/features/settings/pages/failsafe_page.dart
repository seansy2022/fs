import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../models/app_settings_state.dart';
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

  Future<void> _saveConfig() async {
    try {
      await ref.read(receiverRepositoryProvider).writeFailsafe(
        ReceiverFailsafeConfig(
          throttleUs: _throttleHold ? 0 : _throttleUs,
          steeringUs: _steeringHold ? 0 : _steeringUs,
        ),
      );
    } catch (_) {
      if (mounted) {
        await AlertIconWidget.show(
          context,
          title: '保存失败',
          message: '无法保存失控保护设置，请重试。',
          confirmText: '确定',
        );
      }
    }
  }

  Future<void> _startTest() async {
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
  }

  Future<void> _restoreControl() async {
    if (!mounted) return;
    setState(() => _testing = false);
    await ref.read(receiverRepositoryProvider).startControlLoop();
  }

  @override
  Widget build(BuildContext context) {
    final connected =
        ref.watch(receiverConnectionProvider).valueOrNull ==
        ReceiverConnectionState.connected;
    final settings = ref.watch(appSettingsProvider);

    // Dynamic auxiliary channels with non-none function
    final auxChannels = settings.channels
        .asMap()
        .entries
        .where((e) => e.key >= 2 && e.value.function != AuxiliaryFunction.none)
        .toList(growable: false);

    return Column(
      children: [
        _FailsafeChannelStrip(
          title: '方向',
          valueUs: _steeringUs,
          hold: _steeringHold,
          onHoldChanged: (v) => setState(() => _steeringHold = v),
          onValueChanged: (v) => setState(() => _steeringUs = v),
          enabled: connected,
        ),
        const SizedBox(height: 8),
        _FailsafeChannelStrip(
          title: '油门',
          valueUs: _throttleUs,
          hold: _throttleHold,
          onHoldChanged: (v) => setState(() => _throttleHold = v),
          onValueChanged: (v) => setState(() => _throttleUs = v),
          enabled: connected,
        ),
        const SizedBox(height: 8),
        // Auxiliary channels (informational - protocol doesn't support aux failsafe)
        for (final entry in auxChannels) ...[
          SettingsStrip(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${entry.value.channelLabel} (${_functionLabel(entry.value.function)})',
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                  ),
                ),
                const Text(
                  '保持',
                  style: TextStyle(color: AppColors.textDim, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Save button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PrimaryButton(
            text: '保存设置',
            width: double.infinity,
            enabled: connected && !_testing,
            onTap: connected && !_testing ? _saveConfig : null,
          ),
        ),
        const SizedBox(height: 12),
        // Test button
        Center(
          child: SizedBox(
            width: 174,
            height: 44,
            child: PrimaryButton(
              text: _testing ? '测试中...' : '测试',
              type: PrimaryButtonType.normal,
              enabled: connected && !_testing,
              padding: EdgeInsets.zero,
              onTap: connected && !_testing ? _startTest : null,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _functionLabel(AuxiliaryFunction function) {
    switch (function) {
      case AuxiliaryFunction.none:
        return '无';
      case AuxiliaryFunction.headlight:
        return '大灯';
      case AuxiliaryFunction.warningLight:
        return '警示灯';
      case AuxiliaryFunction.gearControl:
        return '挡位控制';
      case AuxiliaryFunction.gyro:
        return '陀螺仪';
      case AuxiliaryFunction.brakeLight:
        return '刹车灯';
      case AuxiliaryFunction.reverseLight:
        return '倒车灯';
      case AuxiliaryFunction.leftSignal:
        return '左转灯';
      case AuxiliaryFunction.rightSignal:
        return '右转灯';
    }
  }
}

class _FailsafeChannelStrip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SettingsStrip(
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              title,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
            ),
          ),
          const Spacer(),
          ItemButton(
            text: '保持',
            selected: hold,
            fontSize: 14,
            width: 74,
            height: 28,
            onTap: enabled ? () => onHoldChanged(true) : null,
          ),
          const SizedBox(width: 12),
          ItemButton(
            text: '固定值',
            selected: !hold,
            fontSize: 14,
            width: 74,
            height: 28,
            onTap: enabled ? () => onHoldChanged(false) : null,
          ),
          if (!hold) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: enabled ? () => _editValue(context) : null,
              child: Container(
                width: 72,
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
                  '${valueUs}us',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: AppFonts.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editValue(BuildContext context) {
    final controller = TextEditingController(text: valueUs.toString());
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
                '输入数值 (us)',
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
                      final text = controller.text.trim();
                      final parsed = int.tryParse(text);
                      if (parsed != null) {
                        onValueChanged(parsed.clamp(1000, 2000));
                      }
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

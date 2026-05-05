import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../controllers/settings_controller.dart';
import '../models/app_settings_state.dart';
import '../widgets/select_option_toggle.dart';
import '../widgets/settings_workspace.dart';

class ChannelSettingsPage extends ConsumerWidget {
  const ChannelSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsWorkspace(
      activeRoute: AppRoutes.channelSettings,
      onBack: () => Navigator.of(context).pop(),
      content: const ChannelSettingsContent(),
    );
  }
}

class ChannelSettingsContent extends ConsumerStatefulWidget {
  const ChannelSettingsContent({super.key});

  @override
  ConsumerState<ChannelSettingsContent> createState() =>
      _ChannelSettingsContentState();
}

class _ChannelSettingsContentState
    extends ConsumerState<ChannelSettingsContent> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    final ch1 = _channelAt(settings.channels, 0);
    final ch2 = _channelAt(settings.channels, 1);
    final ch3 = _channelAt(settings.channels, 2);
    final ch4 = _channelAt(settings.channels, 3);

    // Dynamic auxiliary rows: all channels except CH1/CH2 with function != none
    final auxChannels = settings.channels.asMap().entries.where((e) =>
        e.key >= 2 && e.value.function != AuxiliaryFunction.none);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildChannelRow(
            channelIndex: 0,
            label: '方向(CH1)',
            channel: ch1,
            controller: controller,
            showFunction: false,
          ),
          const SizedBox(height: 8),
          _buildChannelRow(
            channelIndex: 1,
            label: '油门(CH2)',
            channel: ch2,
            controller: controller,
            showFunction: false,
          ),
          const SizedBox(height: 8),
          _buildChannelRow(
            channelIndex: 2,
            label: _channelLabel(ch3, 'CH3'),
            channel: ch3,
            controller: controller,
            showFunction: true,
          ),
          if (ch3.function == AuxiliaryFunction.none) const SizedBox(height: 8),
          if (ch3.function == AuxiliaryFunction.none)
            const SizedBox.shrink()
          else ...[
            _buildChannelProgressBar(ch3),
            const SizedBox(height: 8),
          ],
          _buildChannelRow(
            channelIndex: 3,
            label: _channelLabel(ch4, 'CH4'),
            channel: ch4,
            controller: controller,
            showFunction: true,
          ),
          if (ch4.function == AuxiliaryFunction.none) ...[
            const SizedBox(height: 8),
            // CH4 with no function: show function selector only
            SettingsStrip(
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _channelLabel(ch4, 'CH4'),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _selectFunction(context, 3, ch4, controller),
                    child: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textDim,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (ch4.function != AuxiliaryFunction.none) ...[
            _buildChannelProgressBar(ch4),
            const SizedBox(height: 8),
          ],
          // Dynamic auxiliary channel rows
          for (final entry in auxChannels
              .where((e) => e.key > 3)) ...[
            _buildChannelRow(
              channelIndex: entry.key,
              label: '${entry.value.channelLabel} (${_functionLabel(entry.value.function)})',
              channel: entry.value,
              controller: controller,
              showFunction: false,
            ),
            if (entry.value.function != AuxiliaryFunction.none) ...[
              _buildChannelProgressBar(entry.value),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelRow({
    required int channelIndex,
    required String label,
    required ChannelSetting channel,
    required SettingsController controller,
    required bool showFunction,
  }) {
    return SettingsStrip(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: showFunction ? 28 : 22,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
            ),
          ),
          const _FieldLabel('低'),
          Expanded(
            flex: 12,
            child: _EditableChannelValue(
              value: channel.lowPercent.round(),
              onChanged: (v) {
                controller.updateChannel(
                  channelIndex,
                  channel.copyWith(lowPercent: v.toDouble()),
                );
              },
            ),
          ),
          const _FieldLabel('高'),
          Expanded(
            flex: 12,
            child: _EditableChannelValue(
              value: channel.highPercent.round(),
              onChanged: (v) {
                controller.updateChannel(
                  channelIndex,
                  channel.copyWith(highPercent: v.toDouble()),
                );
              },
            ),
          ),
          const _FieldLabel('中'),
          Expanded(
            flex: 12,
            child: _EditableChannelValue(
              value: channel.trimPercent.round(),
              onChanged: (v) {
                controller.updateChannel(
                  channelIndex,
                  channel.copyWith(trimPercent: v.toDouble()),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          SelectOptionToggle(
            selected: channel.reversed,
            label: '反向',
            onTap: () {
              controller.updateChannel(
                channelIndex,
                channel.copyWith(reversed: !channel.reversed),
              );
            },
          ),
          if (showFunction) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () =>
                  _selectFunction(context, channelIndex, channel, controller),
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.textDim,
                size: 22,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelProgressBar(ChannelSetting channel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: _ChannelProgressBar(
        lowPercent: channel.lowPercent.round(),
        highPercent: channel.highPercent.round(),
        trimPercent: channel.trimPercent.round(),
      ),
    );
  }

  String _channelLabel(ChannelSetting channel, String fallback) {
    if (channel.function == AuxiliaryFunction.none) return fallback;
    return '${channel.channelLabel} (${_functionLabel(channel.function)})';
  }

  void _selectFunction(
    BuildContext context,
    int index,
    ChannelSetting channel,
    SettingsController controller,
  ) {
    final options = index == 2
        ? const <AuxiliaryFunction>[
            AuxiliaryFunction.none,
            AuxiliaryFunction.headlight,
            AuxiliaryFunction.warningLight,
            AuxiliaryFunction.gearControl,
            AuxiliaryFunction.gyro,
          ]
        : AuxiliaryFunction.values;

    AlertListDialog.show(
      context,
      title: '选择辅助功能',
      width: 350,
      options: options.map(_functionLabel).toList(growable: false),
      selectedOption: _functionLabel(channel.function),
      onOptionSelected: (selection) {
        controller.updateChannel(
          index,
          channel.copyWith(
            function: options.firstWhere(
              (value) => _functionLabel(value) == selection,
            ),
          ),
        );
      },
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

  ChannelSetting _channelAt(List<ChannelSetting> channels, int index) {
    if (index < channels.length) {
      return channels[index];
    }
    return ChannelSetting(
      channelLabel: 'CH${index + 1}',
      title: '辅助通道',
      function: AuxiliaryFunction.none,
      lowPercent: -100,
      highPercent: 100,
      trimPercent: 0,
      reversed: false,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.text, fontSize: 14),
      ),
    );
  }
}

class _EditableChannelValue extends StatelessWidget {
  const _EditableChannelValue({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  void _onTap(BuildContext context) {
    final controller = TextEditingController(text: value.toString());
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
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
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
                        onChanged(parsed.clamp(-100, 100));
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

  @override
  Widget build(BuildContext context) {
    return Align(
      child: GestureDetector(
        onTap: () => _onTap(context),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x661B2D4D),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF0072FF), width: 0.5),
          ),
          child: Text(
            '$value%',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: AppFonts.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChannelProgressBar extends StatelessWidget {
  const _ChannelProgressBar({
    required this.lowPercent,
    required this.highPercent,
    required this.trimPercent,
  });

  final int lowPercent;
  final int highPercent;
  final int trimPercent;

  @override
  Widget build(BuildContext context) {
    const rangeMin = -100.0;
    const rangeMax = 100.0;
    const range = rangeMax - rangeMin;

    double pos(double value) => ((value - rangeMin) / range) * 100;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final lowPos = pos(lowPercent.toDouble());
          final highPos = pos(highPercent.toDouble());
          final trimPos = pos(trimPercent.toDouble());
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Background track
              Center(
                child: Container(
                  height: 4,
                  width: width,
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Active range (low to high)
              Positioned(
                left: lowPos / 100 * width,
                width: (highPos - lowPos) / 100 * width,
                top: 10,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFF00FF88)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Center mark
              Positioned(
                left: pos(0) / 100 * width - 4,
                top: 6,
                child: Container(
                  width: 8,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.textDim,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              // Trim mark
              Positioned(
                left: trimPos / 100 * width - 5,
                top: 2,
                child: Container(
                  width: 10,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C6FF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

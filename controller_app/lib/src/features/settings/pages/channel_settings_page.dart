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
  final Map<int, _ChannelValueField> _selectedFields =
      <int, _ChannelValueField>{};

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
          const SizedBox(height: 8),
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
            child: _ChannelValueButton(
              value: channel.lowPercent.round(),
              active: _selectedFields[channelIndex] == _ChannelValueField.low,
              onTap: () => _selectField(channelIndex, _ChannelValueField.low),
            ),
          ),
          const _FieldLabel('高'),
          Expanded(
            flex: 12,
            child: _ChannelValueButton(
              value: channel.highPercent.round(),
              active: _selectedFields[channelIndex] == _ChannelValueField.high,
              onTap: () => _selectField(channelIndex, _ChannelValueField.high),
            ),
          ),
          const _FieldLabel('中'),
          Expanded(
            flex: 12,
            child: _ChannelValueButton(
              value: channel.trimPercent.round(),
              active: _selectedFields[channelIndex] == _ChannelValueField.trim,
              onTap: () => _selectField(channelIndex, _ChannelValueField.trim),
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

  void _selectField(int channelIndex, _ChannelValueField field) {
    if (_selectedFields[channelIndex] == field) return;
    setState(() {
      _selectedFields[channelIndex] = field;
    });
  }
}

enum _ChannelValueField { low, high, trim }

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

class _ChannelValueButton extends StatelessWidget {
  const _ChannelValueButton({
    required this.value,
    required this.active,
    required this.onTap,
  });

  final int value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: RCButton(
        onTap: onTap,
        active: active,
        enableRepeat: false,
        width: 60,
        height: 28,
        padding: EdgeInsets.zero,
        textWidget: Text(
          '$value%',
          style: TextStyle(
            color: active ? AppColors.text : AppColors.textDim,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

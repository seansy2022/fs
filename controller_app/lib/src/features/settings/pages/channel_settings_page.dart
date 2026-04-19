import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../controllers/settings_controller.dart';
import '../models/app_settings_state.dart';
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
  final Map<int, int> _selectedValueIndex = {0: 0, 1: 0, 2: 0};

  bool _isSelected(int channelIndex, int valueIndex) =>
      _selectedValueIndex[channelIndex] == valueIndex;

  void _setSelected(int channelIndex, int valueIndex) {
    if (_selectedValueIndex[channelIndex] == valueIndex) return;
    if (!mounted) return;
    setState(() {
      _selectedValueIndex[channelIndex] = valueIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);
    final ch1 = _channelAt(
      settings.channels,
      0,
      channelLabel: 'CH1',
      title: '方向',
    );
    final ch2 = _channelAt(
      settings.channels,
      1,
      channelLabel: 'CH2',
      title: '油门',
    );
    final ch3 = _channelAt(
      settings.channels,
      2,
      channelLabel: 'CH3',
      title: '大灯',
    );
    final ch4 = _channelAt(
      settings.channels,
      3,
      channelLabel: 'CH4',
      title: '无',
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          SettingsStrip(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 22,
                  child: const Text(
                    '方向(CH1)',
                    style: TextStyle(color: AppColors.text, fontSize: 14),
                  ),
                ),
                const _FieldLabel('低'),
                Expanded(
                  flex: 12,
                  child: _ChannelValueButton(
                    text: '${ch1.lowPercent.round()}%',
                    active: _isSelected(0, 0),
                    onTap: () => _setSelected(0, 0),
                  ),
                ),
                const _FieldLabel('高'),
                Expanded(
                  flex: 12,
                  child: _ChannelValueButton(
                    text: '${ch1.highPercent.round()}%',
                    active: _isSelected(0, 1),
                    onTap: () => _setSelected(0, 1),
                  ),
                ),
                const _FieldLabel('中'),
                Expanded(
                  flex: 12,
                  child: _ChannelValueButton(
                    text: '${ch1.trimPercent.round()}',
                    active: _isSelected(0, 2),
                    onTap: () => _setSelected(0, 2),
                  ),
                ),
                const SizedBox(width: 12),
                const SizedBox(width: 120, child: _OptionBox(label: '方向')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SettingsStrip(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 22,
                  child: const Text(
                    '油门(CH2)',
                    style: TextStyle(color: AppColors.text, fontSize: 14),
                  ),
                ),
                const _FieldLabel('低'),
                Expanded(
                  flex: 12,
                  child: _ChannelValueButton(
                    text: '${ch2.lowPercent.round()}%',
                    active: _isSelected(1, 0),
                    onTap: () => _setSelected(1, 0),
                  ),
                ),
                const _FieldLabel('高'),
                Expanded(
                  flex: 12,
                  child: _ChannelValueButton(
                    text: '${ch2.highPercent.round()}%',
                    active: _isSelected(1, 1),
                    onTap: () => _setSelected(1, 1),
                  ),
                ),
                const _FieldLabel('中'),
                Expanded(
                  flex: 12,
                  child: _ChannelValueButton(
                    text: '${ch2.trimPercent.round()}',
                    active: _isSelected(1, 2),
                    onTap: () => _setSelected(1, 2),
                  ),
                ),
                const SizedBox(width: 12),
                const SizedBox(width: 120, child: _OptionBox(label: '方向')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SettingsStrip(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 28,
                  child: const Text(
                    '大灯(CH3)',
                    style: TextStyle(color: AppColors.text, fontSize: 14),
                  ),
                ),
                const _FieldLabel('关'),
                Expanded(
                  flex: 12,
                  child: _ChannelValueButton(
                    text: '${ch3.lowPercent.round()}%',
                    active: _isSelected(2, 0),
                    onTap: () => _setSelected(2, 0),
                  ),
                ),
                const _FieldLabel('开'),
                Expanded(
                  flex: 12,
                  child: _ChannelValueButton(
                    text: '${ch3.trimPercent.round()}%',
                    active: _isSelected(2, 1),
                    onTap: () => _setSelected(2, 1),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _selectFunction(context, 2, ch3, controller),
                  child: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textDim,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SettingsStrip(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '无(CH4)',
                    style: TextStyle(color: AppColors.text, fontSize: 14),
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectFunction(context, 3, ch4, controller),
                  child: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textDim,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          SettingsStrip(
            height: 88,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '点击数值单元可切换选中状态，点击通道末尾可配置辅助功能。',
                style: TextStyle(
                  color: AppColors.textDim.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectFunction(
    BuildContext context,
    int index,
    ChannelSetting channel,
    SettingsController controller,
  ) {
    AlertSelectionSheet.show(
      context,
      title: '选择辅助功能',
      options: AuxiliaryFunction.values
          .map(_functionLabel)
          .toList(growable: false),
      selectedOption: _functionLabel(channel.function),
      onOptionSelected: (selection) {
        controller.updateChannel(
          index,
          channel.copyWith(
            function: AuxiliaryFunction.values.firstWhere(
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

  ChannelSetting _channelAt(
    List<ChannelSetting> channels,
    int index, {
    required String channelLabel,
    required String title,
  }) {
    if (index < channels.length) {
      return channels[index];
    }
    return ChannelSetting(
      channelLabel: channelLabel,
      title: title,
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

class _ChannelValueButton extends StatelessWidget {
  const _ChannelValueButton({
    required this.text,
    required this.onTap,
    this.active = false,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: ItemButton(
        text: text,
        selected: active,
        fontSize: 14,
        onTap: onTap,
      ),
    );
  }
}

class _OptionBox extends StatelessWidget {
  const _OptionBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return RCButton(
      onTap: null,
      enableRepeat: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      textWidget: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.text, fontSize: 14),
      ),
    );
  }
}

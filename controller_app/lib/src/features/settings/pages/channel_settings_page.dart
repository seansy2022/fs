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

  bool _isSpecialAuxChannel(int channelIndex) =>
      channelIndex == 2 || channelIndex == 3;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    final ch1 = _channelAt(settings.channels, 0);
    final ch2 = _channelAt(settings.channels, 1);
    final ch3 = _channelAt(settings.channels, 2);
    final ch4 = _channelAt(settings.channels, 3);

    // Dynamic auxiliary rows: all channels except CH1/CH2 with function != none
    final auxChannels = settings.channels.asMap().entries.where(
      (e) => e.key >= 2 && e.value.function != AuxiliaryFunction.none,
    );

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
          if (ch3.function == AuxiliaryFunction.none)
            _buildFunctionSelectorRow(
              channelIndex: 2,
              label: _channelLabel(ch3, 'CH3'),
              channel: ch3,
              controller: controller,
            )
          else
            _buildChannelRow(
              channelIndex: 2,
              label: _channelLabel(ch3, 'CH3'),
              channel: ch3,
              controller: controller,
              showFunction: true,
            ),
          const SizedBox(height: 8),
          if (ch4.function == AuxiliaryFunction.none)
            _buildFunctionSelectorRow(
              channelIndex: 3,
              label: _channelLabel(ch4, 'CH4'),
              channel: ch4,
              controller: controller,
            )
          else
            _buildChannelRow(
              channelIndex: 3,
              label: _channelLabel(ch4, 'CH4'),
              channel: ch4,
              controller: controller,
              showFunction: true,
            ),
          // Dynamic auxiliary channel rows
          for (final entry in auxChannels.where((e) => e.key > 3)) ...[
            _buildChannelRow(
              channelIndex: entry.key,
              label:
                  '${entry.value.channelLabel} (${_functionLabel(entry.value.function)})',
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

  Widget _buildFunctionSelectorRow({
    required int channelIndex,
    required String label,
    required ChannelSetting channel,
    required SettingsController controller,
  }) {
    return SettingsStrip(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
            ),
          ),
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
    final displaySpec = _displaySpecFor(channelIndex, channel);
    final isSpecialAuxChannel = _isSpecialAuxChannel(channelIndex);
    final labelFlex = _labelFlexFor(
      showFunction: showFunction,
      fieldCount: displaySpec.fields.length,
      isSpecialAuxChannel: isSpecialAuxChannel,
    );

    return SettingsStrip(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: labelFlex,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
            ),
          ),
          for (final field in displaySpec.fields) ...[
            _FieldLabel(field.label),
            Expanded(
              flex: 12,
              child: field.inputType == _ChannelFieldInputType.button
                  ? _ChannelValueButton(
                      value: _valueForField(channel, field.field).round(),
                      active: _selectedFields[channelIndex] == field.field,
                      onTap: () => _selectField(channelIndex, field.field),
                    )
                  : _ChannelValueInput(
                      value: _valueForField(channel, field.field).round(),
                      onChanged: (value) => _updateChannelField(
                        controller,
                        channelIndex,
                        channel,
                        field.field,
                        value.toDouble(),
                      ),
                    ),
            ),
          ],
          if (!isSpecialAuxChannel) ...[
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
          ],
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
    if (channel.function == AuxiliaryFunction.none) {
      return '无(${channel.channelLabel.isNotEmpty ? channel.channelLabel : fallback})';
    }
    return '${_functionLabel(channel.function)}(${channel.channelLabel})';
  }

  int _labelFlexFor({
    required bool showFunction,
    required int fieldCount,
    required bool isSpecialAuxChannel,
  }) {
    if (!isSpecialAuxChannel) {
      return showFunction ? 28 : 22;
    }
    switch (fieldCount) {
      case 1:
        return 42;
      case 2:
        return 34;
      default:
        return 28;
    }
  }

  void _selectFunction(
    BuildContext context,
    int index,
    ChannelSetting channel,
    SettingsController controller,
  ) {
    final siblingChannelIndex = index == 2
        ? 3
        : index == 3
        ? 2
        : null;
    final siblingFunction = siblingChannelIndex == null
        ? AuxiliaryFunction.none
        : _channelAt(
            ref.read(appSettingsProvider).channels,
            siblingChannelIndex,
          ).function;
    final options = _functionOptionsForChannel(
      index,
      currentFunction: channel.function,
      excludedFunction: siblingFunction,
    );

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

  List<AuxiliaryFunction> _functionOptionsForChannel(
    int index, {
    required AuxiliaryFunction currentFunction,
    required AuxiliaryFunction excludedFunction,
  }) {
    if (index == 2 || index == 3) {
      return <AuxiliaryFunction>[
            AuxiliaryFunction.none,
            AuxiliaryFunction.headlight,
            AuxiliaryFunction.warningLight,
            AuxiliaryFunction.gearControl,
            AuxiliaryFunction.gyro,
          ]
          .where((function) {
            if (function == AuxiliaryFunction.none) {
              return true;
            }
            if (function == currentFunction) {
              return true;
            }
            return function != excludedFunction;
          })
          .toList(growable: false);
    }
    return AuxiliaryFunction.values;
  }

  _ChannelDisplaySpec _displaySpecFor(
    int channelIndex,
    ChannelSetting channel,
  ) {
    if (channelIndex != 2 && channelIndex != 3) {
      return _ChannelDisplaySpec.defaultSpec;
    }

    switch (channel.function) {
      case AuxiliaryFunction.headlight:
      case AuxiliaryFunction.warningLight:
        return const _ChannelDisplaySpec(<_ChannelDisplayFieldSpec>[
          _ChannelDisplayFieldSpec('关', _ChannelValueField.low),
          _ChannelDisplayFieldSpec('开', _ChannelValueField.high),
        ]);
      case AuxiliaryFunction.gearControl:
        return const _ChannelDisplaySpec(<_ChannelDisplayFieldSpec>[
          _ChannelDisplayFieldSpec('低', _ChannelValueField.low),
          _ChannelDisplayFieldSpec('高', _ChannelValueField.high),
          _ChannelDisplayFieldSpec('空', _ChannelValueField.trim),
        ]);
      case AuxiliaryFunction.gyro:
        return const _ChannelDisplaySpec(<_ChannelDisplayFieldSpec>[
          _ChannelDisplayFieldSpec(
            '设置值',
            _ChannelValueField.trim,
            inputType: _ChannelFieldInputType.input,
          ),
        ]);
      case AuxiliaryFunction.none:
      case AuxiliaryFunction.brakeLight:
      case AuxiliaryFunction.reverseLight:
      case AuxiliaryFunction.leftSignal:
      case AuxiliaryFunction.rightSignal:
        return _ChannelDisplaySpec.defaultSpec;
    }
  }

  double _valueForField(ChannelSetting channel, _ChannelValueField field) {
    switch (field) {
      case _ChannelValueField.low:
        return channel.lowPercent;
      case _ChannelValueField.high:
        return channel.highPercent;
      case _ChannelValueField.trim:
        return channel.trimPercent;
    }
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

  void _updateChannelField(
    SettingsController controller,
    int channelIndex,
    ChannelSetting channel,
    _ChannelValueField field,
    double value,
  ) {
    switch (field) {
      case _ChannelValueField.low:
        controller.updateChannel(
          channelIndex,
          channel.copyWith(lowPercent: value),
        );
      case _ChannelValueField.high:
        controller.updateChannel(
          channelIndex,
          channel.copyWith(highPercent: value),
        );
      case _ChannelValueField.trim:
        controller.updateChannel(
          channelIndex,
          channel.copyWith(trimPercent: value),
        );
    }
  }
}

enum _ChannelValueField { low, high, trim }

enum _ChannelFieldInputType { button, input }

class _ChannelDisplaySpec {
  const _ChannelDisplaySpec(this.fields);

  static const defaultSpec = _ChannelDisplaySpec(<_ChannelDisplayFieldSpec>[
    _ChannelDisplayFieldSpec('低', _ChannelValueField.low),
    _ChannelDisplayFieldSpec('高', _ChannelValueField.high),
    _ChannelDisplayFieldSpec('中', _ChannelValueField.trim),
  ]);

  final List<_ChannelDisplayFieldSpec> fields;
}

class _ChannelDisplayFieldSpec {
  const _ChannelDisplayFieldSpec(
    this.label,
    this.field, {
    this.inputType = _ChannelFieldInputType.button,
  });

  final String label;
  final _ChannelValueField field;
  final _ChannelFieldInputType inputType;
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

class _ChannelValueInput extends StatelessWidget {
  const _ChannelValueInput({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  void _openEditor(BuildContext context) {
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
                '输入数值 (%)',
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
                      final parsed = int.tryParse(controller.text.trim());
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
    return GestureDetector(
      onTap: () => _openEditor(context),
      child: Container(
        width: 60,
        height: 28,
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
            fontSize: 13,
            fontWeight: AppFonts.w700,
          ),
        ),
      ),
    );
  }
}

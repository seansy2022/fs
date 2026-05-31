import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../controllers/settings_controller.dart';
import '../models/app_settings_state.dart';
import '../widgets/numeric_input_dialog.dart';
import '../widgets/select_option_toggle.dart';
import '../widgets/settings_action_button.dart';
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
    final auxChannels = settings.channels.asMap().entries.where(
      (entry) =>
          entry.key > 3 && entry.value.function != AuxiliaryFunction.none,
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildChannelRow(
            channelIndex: 0,
            label: '方向(CH1)',
            channel: ch1,
            controller: controller,
          ),
          const SizedBox(height: 8),
          _buildChannelRow(
            channelIndex: 1,
            label: '油门(CH2)',
            channel: ch2,
            controller: controller,
          ),
          const SizedBox(height: 8),
          _buildAuxChannelCard(
            channelIndex: 2,
            channel: ch3,
            controller: controller,
          ),
          const SizedBox(height: 8),
          _buildAuxChannelCard(
            channelIndex: 3,
            channel: ch4,
            controller: controller,
          ),
          for (final entry in auxChannels) ...[
            const SizedBox(height: 8),
            _buildChannelRow(
              channelIndex: entry.key,
              label:
                  '${entry.value.channelLabel} (${_functionLabel(entry.value.function)})',
              channel: entry.value,
              controller: controller,
            ),
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
  }) {
    return SettingsStrip(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            SizedBox(
              width: _leadingLabelWidth(context, constraints.maxWidth),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.text, fontSize: 14),
              ),
            ),
            for (final field in _ChannelDisplaySpec.defaultSpec.fields) ...[
              _FieldLabel(field.label, width: 32),
              Expanded(
                flex: 12,
                child: _ChannelValueButton(
                  width: _channelValueButtonWidth(channelIndex),
                  value: _valueForField(channel, field.field).round(),
                  active: _selectedFields[channelIndex] == field.field,
                  onTap: () => _editChannelValue(
                    context: context,
                    channelIndex: channelIndex,
                    channel: channel,
                    field: field.field,
                    controller: controller,
                  ),
                ),
              ),
            ],
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
        ),
      ),
    );
  }

  Widget _buildAuxChannelCard({
    required int channelIndex,
    required ChannelSetting channel,
    required SettingsController controller,
  }) {
    return SettingsStrip(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final configSection = _buildAuxConfigSection(
            channelIndex: channelIndex,
            channel: channel,
            controller: controller,
            maxWidth: constraints.maxWidth,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: _leadingLabelWidth(context, constraints.maxWidth),
                    child: Text(
                      'CH${channelIndex + 1}(${channel.displayName})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const _AuxLabel('控制类型'),
                  const SizedBox(width: 16),
                  _AuxSelectField(
                    label: _controlTypeLabel(channel.controlType),
                    onTap: () => _selectControlType(
                      context,
                      channelIndex,
                      channel,
                      controller,
                    ),
                  ),
                  SizedBox(width: _auxTypeNameSpacing()),
                  const _AuxLabel('名称'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AuxNameField(
                      key: ValueKey<String>('aux-name-$channelIndex'),
                      value: channel.displayName,
                      onChanged: (value) {
                        controller.updateChannel(
                          channelIndex,
                          channel.copyWith(
                            displayName: value.trim().isEmpty
                                ? '辅助${channelIndex - 1}'
                                : value,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (configSection != null) ...[
                Padding(
                  padding: EdgeInsets.only(
                    left: _leadingLabelWidth(context, constraints.maxWidth),
                    top: 8,
                    bottom: 8,
                  ),
                  child: Container(height: 1, color: const Color(0xFF233854)),
                ),
                const SizedBox(height: 14),
                configSection,
              ],
            ],
          );
        },
      ),
    );
  }

  double _leadingLabelWidth(BuildContext context, double maxWidth) {
    const fieldLabelTotalWidth = 32.0 * 3;
    const spacingWidth = 12.0;
    final reverseTextPainter = TextPainter(
      text: const TextSpan(
        text: '反向',
        style: TextStyle(color: AppColors.text, fontSize: 14),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    final toggleWidth = 24.0 + 8.0 + reverseTextPainter.width;
    final flexibleWidth =
        (maxWidth - fieldLabelTotalWidth - spacingWidth - toggleWidth).clamp(
          0.0,
          double.infinity,
        );
    return flexibleWidth * 22 / 58;
  }

  double _channelValueButtonWidth(int channelIndex) {
    return channelIndex < 2 ? 60 : 80;
  }

  double _auxTypeNameSpacing() {
    return 40;
  }

  Widget? _buildAuxConfigSection({
    required int channelIndex,
    required ChannelSetting channel,
    required SettingsController controller,
    required double maxWidth,
  }) {
    final inset = _leadingLabelWidth(context, maxWidth);
    final itemWidth = ((maxWidth - inset - 32) / 3).clamp(0.0, double.infinity);
    switch (channel.controlType) {
      case AuxControlType.disabled:
        return null;
      case AuxControlType.switchControl:
        return Padding(
          padding: EdgeInsets.only(left: inset),
          child: Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _AuxValueEditor(
                label: '开',
                value: channel.switchValues[0].round(),
                onChanged: (value) => _updateSwitchValue(
                  controller,
                  channelIndex,
                  channel,
                  0,
                  value.toDouble(),
                ),
              ),
              _AuxValueEditor(
                label: '关',
                value: channel.switchValues[1].round(),
                onChanged: (value) => _updateSwitchValue(
                  controller,
                  channelIndex,
                  channel,
                  1,
                  value.toDouble(),
                ),
              ),
            ],
          ),
        );
      case AuxControlType.multiState:
        return Padding(
          padding: EdgeInsets.only(left: inset),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              for (
                var index = 0;
                index < channel.multiStateValues.length;
                index++
              )
                _AuxValueEditor(
                  width: itemWidth,
                  inputWidth: (itemWidth - 48).clamp(0.0, double.infinity),
                  label: '状态${index + 1}',
                  value: channel.multiStateValues[index].round(),
                  onChanged: (value) => _updateMultiStateValue(
                    controller,
                    channelIndex,
                    channel,
                    index,
                    value.toDouble(),
                  ),
                ),
              _MultiStateActionButtons(
                width: itemWidth,
                showDelete: channel.multiStateValues.length > 3,
                onDelete: () =>
                    _removeMultiStateValue(controller, channelIndex, channel),
                onTap: () =>
                    _addMultiStateValue(controller, channelIndex, channel),
              ),
            ],
          ),
        );
      case AuxControlType.value:
        return Padding(
          padding: EdgeInsets.only(left: inset),
          child: _AuxValueEditor(
            label: '设置值',
            labelWidth: null,
            spacing: 16,
            value: channel.singleValue.round(),
            onChanged: (value) {
              controller.updateChannel(
                channelIndex,
                channel.copyWith(
                  singleValue: value.toDouble(),
                  trimPercent: value.toDouble(),
                  function: _legacyFunctionForControlType(
                    channelIndex,
                    AuxControlType.value,
                    currentFunction: channel.function,
                  ),
                ),
              );
            },
          ),
        );
    }
  }

  void _selectControlType(
    BuildContext context,
    int channelIndex,
    ChannelSetting channel,
    SettingsController controller,
  ) {
    final options = AuxControlType.values
        .map(_controlTypeLabel)
        .toList(growable: false);

    AlertListDialog.show(
      context,
      title: '控制类型',
      width: 300,
      options: options,
      selectedOption: _controlTypeLabel(channel.controlType),
      onOptionSelected: (selection) {
        final selectedType = AuxControlType.values.firstWhere(
          (value) => _controlTypeLabel(value) == selection,
        );
        controller.updateChannel(
          channelIndex,
          channel.copyWith(
            controlType: selectedType,
            function: _legacyFunctionForControlType(
              channelIndex,
              selectedType,
              currentFunction: channel.function,
            ),
          ),
        );
      },
    );
  }

  void _updateSwitchValue(
    SettingsController controller,
    int channelIndex,
    ChannelSetting channel,
    int valueIndex,
    double value,
  ) {
    final next = List<double>.of(channel.switchValues);
    next[valueIndex] = value;
    controller.updateChannel(
      channelIndex,
      channel.copyWith(
        switchValues: next,
        highPercent: next[0],
        lowPercent: next[1],
        function: _legacyFunctionForControlType(
          channelIndex,
          AuxControlType.switchControl,
          currentFunction: channel.function,
        ),
      ),
    );
  }

  void _updateMultiStateValue(
    SettingsController controller,
    int channelIndex,
    ChannelSetting channel,
    int valueIndex,
    double value,
  ) {
    final next = List<double>.of(channel.multiStateValues);
    next[valueIndex] = value;
    controller.updateChannel(
      channelIndex,
      channel.copyWith(
        multiStateValues: next,
        function: _legacyFunctionForControlType(
          channelIndex,
          AuxControlType.multiState,
          currentFunction: channel.function,
        ),
      ),
    );
  }

  void _addMultiStateValue(
    SettingsController controller,
    int channelIndex,
    ChannelSetting channel,
  ) {
    final next = List<double>.of(channel.multiStateValues)..add(0);
    controller.updateChannel(
      channelIndex,
      channel.copyWith(
        multiStateValues: next,
        function: _legacyFunctionForControlType(
          channelIndex,
          AuxControlType.multiState,
          currentFunction: channel.function,
        ),
      ),
    );
  }

  void _removeMultiStateValue(
    SettingsController controller,
    int channelIndex,
    ChannelSetting channel,
  ) {
    if (channel.multiStateValues.length <= 3) {
      return;
    }
    final next = List<double>.of(channel.multiStateValues)..removeLast();
    controller.updateChannel(
      channelIndex,
      channel.copyWith(
        multiStateValues: next,
        function: _legacyFunctionForControlType(
          channelIndex,
          AuxControlType.multiState,
          currentFunction: channel.function,
        ),
      ),
    );
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

  String _controlTypeLabel(AuxControlType type) {
    switch (type) {
      case AuxControlType.disabled:
        return '禁用';
      case AuxControlType.switchControl:
        return '开关';
      case AuxControlType.multiState:
        return '多状态';
      case AuxControlType.value:
        return '值';
    }
  }

  AuxiliaryFunction _legacyFunctionForControlType(
    int channelIndex,
    AuxControlType type, {
    required AuxiliaryFunction currentFunction,
  }) {
    switch (type) {
      case AuxControlType.disabled:
        return AuxiliaryFunction.none;
      case AuxControlType.switchControl:
        if (currentFunction == AuxiliaryFunction.warningLight ||
            currentFunction == AuxiliaryFunction.headlight) {
          return currentFunction;
        }
        return channelIndex == 3
            ? AuxiliaryFunction.warningLight
            : AuxiliaryFunction.headlight;
      case AuxControlType.multiState:
        return AuxiliaryFunction.gearControl;
      case AuxControlType.value:
        return AuxiliaryFunction.gyro;
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
      displayName: index == 2
          ? '辅助1'
          : index == 3
          ? '辅助2'
          : 'CH${index + 1}',
      controlType: AuxControlType.disabled,
      switchValues: const <double>[100, -100],
      multiStateValues: const <double>[0, 0, 0],
      singleValue: 0,
      lowPercent: -100,
      highPercent: 100,
      trimPercent: 0,
      reversed: false,
    );
  }

  void _selectField(int channelIndex, _ChannelValueField field) {
    if (_selectedFields[channelIndex] == field) {
      return;
    }
    setState(() {
      _selectedFields[channelIndex] = field;
    });
  }

  Future<void> _editChannelValue({
    required BuildContext context,
    required int channelIndex,
    required ChannelSetting channel,
    required _ChannelValueField field,
    required SettingsController controller,
  }) async {
    _selectField(channelIndex, field);
    final raw = await NumericInputDialog.show(
      context,
      title: '设置${channel.channelLabel}${_fieldLabel(field)}',
      initialValue: _valueForField(channel, field).round().toString(),
      unit: '%',
      allowSigned: true,
      allowDecimal: false,
      maxLength: 4,
    );
    final value = int.tryParse(raw?.trim() ?? '');
    if (value == null) {
      return;
    }
    controller.updateChannel(
      channelIndex,
      _updateChannelField(channel, field, value.clamp(-100, 100).toDouble()),
    );
  }

  ChannelSetting _updateChannelField(
    ChannelSetting channel,
    _ChannelValueField field,
    double value,
  ) {
    switch (field) {
      case _ChannelValueField.low:
        return channel.copyWith(lowPercent: value);
      case _ChannelValueField.high:
        return channel.copyWith(highPercent: value);
      case _ChannelValueField.trim:
        return channel.copyWith(trimPercent: value);
    }
  }

  String _fieldLabel(_ChannelValueField field) {
    switch (field) {
      case _ChannelValueField.low:
        return '低';
      case _ChannelValueField.high:
        return '高';
      case _ChannelValueField.trim:
        return '中';
    }
  }
}

enum _ChannelValueField { low, high, trim }

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
  const _ChannelDisplayFieldSpec(this.label, this.field);

  final String label;
  final _ChannelValueField field;
}

class _AuxLabel extends StatelessWidget {
  const _AuxLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      style: const TextStyle(color: AppColors.text, fontSize: 14),
    );
  }
}

class _AuxSelectField extends StatelessWidget {
  const _AuxSelectField({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettingsActionButton(label: label, onTap: onTap);
  }
}

class _AuxNameField extends StatefulWidget {
  const _AuxNameField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_AuxNameField> createState() => _AuxNameFieldState();
}

class _AuxNameFieldState extends State<_AuxNameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _AuxNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value || _controller.text == widget.value) {
      return;
    }
    _controller.text = widget.value;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x661B2D4D),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF0072FF), width: 0.9),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: AppFonts.w600,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _AuxValueEditor extends StatelessWidget {
  const _AuxValueEditor({
    required this.label,
    required this.value,
    required this.onChanged,
    this.width,
    this.inputWidth,
    this.labelWidth = 28,
    this.spacing = 0,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final double? width;
  final double? inputWidth;
  final double? labelWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (labelWidth == null)
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
            )
          else
            SizedBox(
              width: label.length > 2 ? 48 : labelWidth,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.text, fontSize: 14),
              ),
            ),
          SizedBox(width: spacing),
          _ChannelValueInput(
            width: inputWidth ?? 60,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MultiStateActionButtons extends StatelessWidget {
  const _MultiStateActionButtons({
    required this.width,
    required this.showDelete,
    required this.onDelete,
    required this.onTap,
  });

  final double width;
  final bool showDelete;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final actionWidth = (width - 48).clamp(0.0, double.infinity);
    return SizedBox(
      width: width,
      child: Row(
        children: [
          if (showDelete)
            SizedBox(
              width: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _MultiStateDeleteIconButton(onTap: onDelete),
              ),
            )
          else
            const SizedBox(width: 48),
          SizedBox(
            width: actionWidth,
            height: 30,
            child: PrimaryButton(
              text: '新增',
              type: PrimaryButtonType.primary,
              enabled: true,
              padding: EdgeInsets.zero,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiStateDeleteIconButton extends StatelessWidget {
  const _MultiStateDeleteIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey<String>('multi-state-delete-icon'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(painter: _MultiStateDeleteIconPainter()),
      ),
    );
  }
}

class _MultiStateDeleteIconPainter extends CustomPainter {
  const _MultiStateDeleteIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF3700)
      ..strokeWidth = 1.67
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.78),
      Offset(size.width * 0.78, size.height * 0.22),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.78),
      Offset(size.width * 0.22, size.height * 0.22),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.value, {required this.width});

  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.text, fontSize: 14),
    );
  }
}

class _ChannelValueButton extends StatelessWidget {
  const _ChannelValueButton({
    required this.width,
    required this.value,
    required this.active,
    required this.onTap,
  });

  final double width;
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
        width: width,
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
  const _ChannelValueInput({
    required this.width,
    required this.value,
    required this.onChanged,
  });

  final double width;
  final int value;
  final ValueChanged<int> onChanged;

  Future<void> _openEditor(BuildContext context) async {
    final raw = await NumericInputDialog.show(
      context,
      title: '设置值',
      initialValue: value.toString(),
      unit: '%',
      allowSigned: true,
      allowDecimal: false,
      maxLength: 4,
    );
    final parsed = int.tryParse(raw?.trim() ?? '');
    if (parsed == null) {
      return;
    }
    onChanged(parsed.clamp(-100, 100));
  }

  @override
  Widget build(BuildContext context) {
    return RCButton(
      onTap: () => _openEditor(context),
      active: false,
      enableRepeat: false,
      width: width,
      height: 28,
      padding: EdgeInsets.zero,
      textWidget: Text(
        '$value%',
        style: const TextStyle(color: AppColors.textDim, fontSize: 14),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../../../core/localization/app_localizations.dart';
import '../controllers/aux_failsafe_sync.dart';
import '../controllers/channel_value_constraints.dart';
import '../models/aux_channel_value_rules.dart';
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
  final Map<int, ChannelValueField> _selectedFields =
      <int, ChannelValueField>{};

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
            channelIndex: 1,
            label: '方向(CH1)',
            channel: ch2,
            controller: controller,
          ),
          const SizedBox(height: 8),
          _buildChannelRow(
            channelIndex: 0,
            label: '油门(CH2)',
            channel: ch1,
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
                AppText.tr(label),
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
              label: AppText.tr('反向'),
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
                      'CH${channelIndex + 1}('
                      '${AppText.tr(channel.displayName)})',
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
                      fallbackValue: '辅助${channelIndex - 1}',
                      onEditingComplete: (value) {
                        controller.updateChannel(
                          channelIndex,
                          channel.copyWith(displayName: value),
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
    final itemWidth = ((maxWidth - 32) / 3).clamp(0.0, double.infinity);
    switch (channel.controlType) {
      case AuxControlType.disabled:
        return null;
      case AuxControlType.switchControl:
        final values = normalizeAuxSwitchValues(channel.switchValues);
        return Padding(
          padding: EdgeInsets.only(left: inset),
          child: Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _AuxValueEditor(
                label: AppText.tr('开'),
                value: values[0].round(),
                onChanged: (value) => _updateSwitchValue(
                  controller,
                  channelIndex,
                  channel,
                  0,
                  value.toDouble(),
                ),
              ),
              _AuxValueEditor(
                label: AppText.tr('关'),
                value: values[1].round(),
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
        final values = normalizeAuxMultiStateValues(channel.multiStateValues);
        final labels = normalizeAuxMultiStateLabels(
          channel.multiStateLabels,
          stateCount: values.length,
        );
        // 多状态配置以整行宽度三等分，不再为标题额外预留左侧空白。
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (var index = 0; index < values.length; index++)
              _buildMultiStateValueEditor(
                itemWidth: itemWidth,
                index: index,
                label: labels[index],
                value: values[index].round(),
                onEditLabel: () => _editMultiStateLabel(
                  context,
                  controller,
                  channelIndex,
                  channel,
                  index,
                  labels[index],
                ),
                onRemove: () => _removeMultiStateValueAt(
                  controller,
                  channelIndex,
                  channel,
                  index,
                ),
                onChanged: (value) => _updateMultiStateValue(
                  controller,
                  channelIndex,
                  channel,
                  index,
                  value.toDouble(),
                ),
              ),
            if (values.length < auxMultiStateMaxCount)
              _MultiStateActionButtons(
                width: itemWidth,
                showDelete: false,
                addEnabled: true,
                onDelete: () {},
                onTap: () =>
                    _addMultiStateValue(controller, channelIndex, channel),
              ),
          ],
        );
      case AuxControlType.value:
        return Padding(
          padding: EdgeInsets.only(left: inset),
          child: _AuxValueEditor(
            label: AppText.tr('设置值'),
            labelWidth: null,
            spacing: 16,
            value: channel.singleValue.round(),
            onChanged: (value) {
              final normalized = normalizeAuxChannelPercent(value);
              controller.updateChannel(
                channelIndex,
                channel.copyWith(
                  singleValue: normalized,
                  trimPercent: normalized,
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

  /// 根据可用宽度调整状态名和数值输入框，保证小屏幕不发生横向溢出。
  Widget _buildMultiStateValueEditor({
    required double itemWidth,
    required int index,
    required String label,
    required int value,
    required VoidCallback onEditLabel,
    required VoidCallback onRemove,
    required ValueChanged<int> onChanged,
  }) {
    final canRemove = index >= auxMultiStateMinCount;
    // RCButton 的最小宽度为 60，按该值计算避免实际渲染超出约束。
    const minimumInputWidth = 60.0;
    const maximumInputWidth = 70.0;
    const labelInputSpacing = 6.0;
    final removalWidth = canRemove ? 28.0 : 0.0;
    final labelWidth =
        (itemWidth - minimumInputWidth - removalWidth - labelInputSpacing)
            .clamp(36.0, 76.0);
    return _AuxValueEditor(
      width: itemWidth,
      // 大屏使用紧凑输入框，剩余空间由三等分列自然留白。
      inputWidth: (itemWidth - labelWidth - removalWidth - labelInputSpacing)
          .clamp(minimumInputWidth, maximumInputWidth),
      labelWidth: labelWidth,
      spacing: labelInputSpacing,
      label: label,
      value: value,
      onEditLabel: onEditLabel,
      onRemove: canRemove ? onRemove : null,
      onChanged: onChanged,
    );
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
      title: AppText.tr('控制类型'),
      width: 300,
      options: options,
      selectedOption: _controlTypeLabel(channel.controlType),
      onOptionSelected: (selection) {
        final selectedType = AuxControlType.values.firstWhere(
          (value) => _controlTypeLabel(value) == selection,
        );
        final becameDisabled =
            selectedType == AuxControlType.disabled &&
            channel.controlType != AuxControlType.disabled;
        controller.updateChannel(
          channelIndex,
          channel.copyWith(
            controlType: selectedType,
            multiStateValues:
                selectedType == AuxControlType.multiState &&
                    channel.controlType != AuxControlType.multiState
                ? defaultAuxMultiStateValues
                : normalizeAuxMultiStateValues(channel.multiStateValues),
            function: _legacyFunctionForControlType(
              channelIndex,
              selectedType,
              currentFunction: channel.function,
            ),
          ),
        );
        if (becameDisabled) {
          unawaited(_syncDisabledAuxFailsafe(channelIndex));
        }
      },
    );
  }

  /// 禁用 CH3/CH4 时，读取当前完整失控保护配置后仅改该路为 1500 us。
  Future<void> _syncDisabledAuxFailsafe(int channelIndex) async {
    if (channelIndex < 2 || channelIndex > 3) {
      return;
    }
    try {
      await syncDisabledAuxFailsafe(
        repository: ref.read(receiverRepositoryProvider),
        channelIndex: channelIndex,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      await AlertIconWidget.show(
        context,
        title: AppText.tr('同步失败'),
        message: AppText.tr('通道已设为禁用，但失控保护参数未能同步到接收机，请检查蓝牙连接后重试。'),
        confirmText: AppText.tr('知道了'),
      );
    }
  }

  void _updateSwitchValue(
    SettingsController controller,
    int channelIndex,
    ChannelSetting channel,
    int valueIndex,
    double value,
  ) {
    final next = normalizeAuxSwitchValues(channel.switchValues);
    next[valueIndex] = normalizeAuxChannelPercent(value);
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
    final next = updateAuxMultiStateValue(
      channel.multiStateValues,
      valueIndex,
      value,
    );
    controller.updateChannel(
      channelIndex,
      channel.copyWith(
        multiStateValues: next,
        multiStateLabels: normalizeAuxMultiStateLabels(
          channel.multiStateLabels,
          stateCount: next.length,
        ),
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
    final next = addAuxMultiStateValue(channel.multiStateValues);
    controller.updateChannel(
      channelIndex,
      channel.copyWith(
        multiStateValues: next,
        multiStateLabels: normalizeAuxMultiStateLabels(
          channel.multiStateLabels,
          stateCount: next.length,
        ),
        function: _legacyFunctionForControlType(
          channelIndex,
          AuxControlType.multiState,
          currentFunction: channel.function,
        ),
      ),
    );
  }

  void _removeMultiStateValueAt(
    SettingsController controller,
    int channelIndex,
    ChannelSetting channel,
    int valueIndex,
  ) {
    if (valueIndex < auxMultiStateMinCount) {
      return;
    }
    final next = removeAuxMultiStateValueAt(
      channel.multiStateValues,
      valueIndex,
    );
    final labels = normalizeAuxMultiStateLabels(
      channel.multiStateLabels,
      stateCount: normalizeAuxMultiStateValues(channel.multiStateValues).length,
    ).toList(growable: true)..removeAt(valueIndex);
    controller.updateChannel(
      channelIndex,
      channel.copyWith(
        multiStateValues: next,
        multiStateLabels: normalizeAuxMultiStateLabels(
          labels,
          stateCount: next.length,
        ),
        function: _legacyFunctionForControlType(
          channelIndex,
          AuxControlType.multiState,
          currentFunction: channel.function,
        ),
      ),
    );
  }

  /// 编辑多状态名称；空值在提交时自动恢复为对应默认名称。
  Future<void> _editMultiStateLabel(
    BuildContext context,
    SettingsController controller,
    int channelIndex,
    ChannelSetting channel,
    int valueIndex,
    String currentValue,
  ) async {
    final value = await TextInputDialog.show(
      context,
      title: AppText.tr('修改状态名称'),
      initialValue: currentValue,
      maxLength: auxMultiStateLabelMaxLength,
    );
    if (value == null) {
      return;
    }
    final stateCount = normalizeAuxMultiStateValues(
      channel.multiStateValues,
    ).length;
    final labels = normalizeAuxMultiStateLabels(
      channel.multiStateLabels,
      stateCount: stateCount,
    ).toList(growable: true);
    labels[valueIndex] = value;
    controller.updateChannel(
      channelIndex,
      channel.copyWith(
        multiStateLabels: normalizeAuxMultiStateLabels(
          labels,
          stateCount: stateCount,
        ),
      ),
    );
  }

  double _valueForField(ChannelSetting channel, ChannelValueField field) {
    switch (field) {
      case ChannelValueField.low:
        return channel.lowPercent;
      case ChannelValueField.high:
        return channel.highPercent;
      case ChannelValueField.trim:
        return channel.trimPercent;
    }
  }

  String _controlTypeLabel(AuxControlType type) {
    switch (type) {
      case AuxControlType.disabled:
        return AppText.tr('禁用');
      case AuxControlType.switchControl:
        return AppText.tr('开关');
      case AuxControlType.multiState:
        return AppText.tr('多状态');
      case AuxControlType.value:
        return AppText.tr('值');
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
        return AppText.tr('无');
      case AuxiliaryFunction.headlight:
        return AppText.tr('大灯');
      case AuxiliaryFunction.warningLight:
        return AppText.tr('警示灯');
      case AuxiliaryFunction.gearControl:
        return AppText.tr('挡位控制');
      case AuxiliaryFunction.gyro:
        return AppText.tr('陀螺仪');
      case AuxiliaryFunction.brakeLight:
        return AppText.tr('刹车灯');
      case AuxiliaryFunction.reverseLight:
        return AppText.tr('倒车灯');
      case AuxiliaryFunction.leftSignal:
        return AppText.tr('左转灯');
      case AuxiliaryFunction.rightSignal:
        return AppText.tr('右转灯');
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
      multiStateValues: defaultAuxMultiStateValues,
      singleValue: 0,
      lowPercent: -100,
      highPercent: 100,
      trimPercent: 0,
      reversed: false,
    );
  }

  void _selectField(int channelIndex, ChannelValueField field) {
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
    required ChannelValueField field,
    required SettingsController controller,
  }) async {
    _selectField(channelIndex, field);
    final constraint = channelPercentConstraintFor(
      field,
      isPrimary: channelIndex < 2,
    );
    final raw = await NumericInputDialog.show(
      context,
      title:
          '${AppText.tr('设置值')} ${channel.channelLabel} '
          '${_fieldLabel(field)}',
      initialValue: _valueForField(channel, field).round().toString(),
      unit: field == ChannelValueField.trim && channelIndex < 2 ? 'us' : '%',
      allowSigned: constraint.allowNegativeInput,
      allowDecimal: false,
      allowPositive: constraint.allowPositiveInput,
      fixedNegativePrefix: constraint.fixedNegativePrefix,
      maxAbsValue: constraint.maxAbsValue,
      maxLength: 4,
    );
    final value = int.tryParse(raw?.trim() ?? '');
    if (value == null) {
      return;
    }
    controller.updateChannel(
      channelIndex,
      _updateChannelField(
        channel,
        field,
        constraint.normalize(value).toDouble(),
      ),
    );
  }

  ChannelSetting _updateChannelField(
    ChannelSetting channel,
    ChannelValueField field,
    double value,
  ) {
    switch (field) {
      case ChannelValueField.low:
        return channel.copyWith(lowPercent: value);
      case ChannelValueField.high:
        return channel.copyWith(highPercent: value);
      case ChannelValueField.trim:
        return channel.copyWith(trimPercent: value);
    }
  }

  String _fieldLabel(ChannelValueField field) {
    switch (field) {
      case ChannelValueField.low:
        return AppText.tr('低');
      case ChannelValueField.high:
        return AppText.tr('高');
      case ChannelValueField.trim:
        return AppText.tr('中');
    }
  }
}

class _ChannelDisplaySpec {
  const _ChannelDisplaySpec(this.fields);

  static const defaultSpec = _ChannelDisplaySpec(<_ChannelDisplayFieldSpec>[
    _ChannelDisplayFieldSpec('低', ChannelValueField.low),
    _ChannelDisplayFieldSpec('高', ChannelValueField.high),
    _ChannelDisplayFieldSpec('中', ChannelValueField.trim),
  ]);

  final List<_ChannelDisplayFieldSpec> fields;
}

class _ChannelDisplayFieldSpec {
  const _ChannelDisplayFieldSpec(this.label, this.field);

  final String label;
  final ChannelValueField field;
}

class _AuxLabel extends StatelessWidget {
  const _AuxLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppText.tr(value),
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
    required this.fallbackValue,
    required this.onEditingComplete,
  });

  final String value;
  final String fallbackValue;
  final ValueChanged<String> onEditingComplete;

  @override
  State<_AuxNameField> createState() => _AuxNameFieldState();
}

class _AuxNameFieldState extends State<_AuxNameField> {
  late final TextEditingController _controller = TextEditingController(
    text: AppText.tr(widget.value),
  );
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChanged);
  late String _lastCommittedValue = widget.value;

  @override
  void didUpdateWidget(covariant _AuxNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) {
      return;
    }
    _lastCommittedValue = widget.value;
    if (_focusNode.hasFocus || _controller.text == AppText.tr(widget.value)) {
      return;
    }
    _controller.text = AppText.tr(widget.value);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  /// 输入框失去焦点时，将临时输入内容提交到设置状态。
  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _commitValue();
    }
  }

  /// 完成编辑后校验名称；空名称恢复默认值，其他内容保留原样。
  void _commitValue() {
    final rawValue = _controller.text.trim();
    final value = rawValue.isEmpty
        ? widget.fallbackValue
        : rawValue == AppText.tr(widget.value)
        ? widget.value
        : rawValue;
    if (_controller.text != value) {
      _controller.text = value;
      _controller.selection = TextSelection.collapsed(offset: value.length);
    }
    if (_lastCommittedValue == value) {
      return;
    }
    _lastCommittedValue = value;
    widget.onEditingComplete(value);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
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
        focusNode: _focusNode,
        inputFormatters: <TextInputFormatter>[
          LengthLimitingTextInputFormatter(5),
        ],
        onSubmitted: (_) => _commitValue(),
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
    this.onEditLabel,
    this.onRemove,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final double? width;
  final double? inputWidth;
  final double? labelWidth;
  final double spacing;
  final VoidCallback? onEditLabel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AuxValueLabel(label: label, width: labelWidth, onEdit: onEditLabel),
          SizedBox(width: spacing),
          _ChannelValueInput(
            width: inputWidth ?? 60,
            value: value,
            onChanged: onChanged,
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            _MultiStateDeleteIconButton(onTap: onRemove!),
          ],
        ],
      ),
    );
  }
}

class _AuxValueLabel extends StatelessWidget {
  const _AuxValueLabel({required this.label, required this.width, this.onEdit});

  final String label;
  final double? width;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      AppText.tr(label),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: AppColors.text, fontSize: 12),
    );
    if (onEdit == null) {
      return width == null
          ? text
          : SizedBox(width: label.length > 2 ? 48 : width, child: text);
    }
    return SizedBox(
      width: width ?? 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(fit: FlexFit.loose, child: text),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEdit,
            child: SizedBox(
              key: const ValueKey<String>('multi-state-label-edit'),
              width: 16,
              height: 16,
              child: SvgPicture.asset(
                'assets/icons/channel_state_edit.svg',
                width: 16,
                height: 16,
              ),
            ),
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
    required this.addEnabled,
    required this.onDelete,
    required this.onTap,
  });

  final double width;
  final bool showDelete;
  final bool addEnabled;
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
              text: AppText.tr('新增'),
              type: PrimaryButtonType.primary,
              enabled: addEnabled,
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
      AppText.tr(value),
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
      title: AppText.tr('设置值'),
      initialValue: value.toString(),
      unit: '%',
      allowSigned: true,
      allowDecimal: false,
      maxAbsValue: auxChannelPercentMax,
      maxLength: 4,
    );
    final parsed = int.tryParse(raw?.trim() ?? '');
    if (parsed == null) {
      return;
    }
    onChanged(normalizeAuxChannelPercent(parsed).round());
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
        style: const TextStyle(color: AppColors.textDim, fontSize: 12),
      ),
    );
  }
}

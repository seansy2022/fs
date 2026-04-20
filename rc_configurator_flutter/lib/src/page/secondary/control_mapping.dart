import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';
import '../../provider/control_mapping_options.dart';
import '../../provider/control_mapping_provider.dart';

const _mappingCellHighlightBase = Color(0x281B2D4D);

class ControlMapping extends ConsumerStatefulWidget {
  const ControlMapping({super.key});

  @override
  ConsumerState<ControlMapping> createState() => _ControlMappingState();
}

class _ControlMappingState extends ConsumerState<ControlMapping> {
  @override
  Widget build(BuildContext context) {
    final mappingState = ref.watch(controlMappingProvider);
    final controller = ref.read(controlMappingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(AppDimens.gapL),
      children: _items(context, mappingState, controller),
    );
  }

  List<Widget> _items(
    BuildContext context,
    ControlMappingState state,
    ControlMappingController c,
  ) {
    final functionModeOptions = functionModeOptionsForChannel(
      state.channel,
      type: state.type,
    );
    final selectedAction = functionModeOptions.contains(state.action)
        ? state.action
        : null;
    final ch5DirectionOptionsList = ch5DirectionOptions(
      _ch5MixingFunctionByAction(state),
    );
    return [
      Stack(
        clipBehavior: Clip.none,
        children: [
          ControlMappingTop(
            selectedChannel: state.channel,
            onTap: c.selectChannel,
          ),
          Positioned(
            bottom: -10,
            left: 0,
            child: _channelHeader(state.channel),
          ),
        ],
      ),
      const SizedBox(height: AppDimens.gapL),
      CellIconTextWidget(
        title: '类型',
        valueText: state.type.isEmpty ? '未设置' : state.type,
        enableHighlight: true,
        highlightGradient: AppGradients.v24,
        highlightBaseColor: _mappingCellHighlightBase,
        onTap: () => _showSheet(
          context,
          '类型',
          state.availableStates,
          state.type.isEmpty ? null : state.type,
          c.updateType,
        ),
      ),
      const SizedBox(height: AppDimens.gapM),
      CellIconTextWidget(
        title: '功能模式',
        valueText: state.action.isEmpty ? '未设置' : state.action,
        enableHighlight: true,
        highlightGradient: AppGradients.v24,
        highlightBaseColor: _mappingCellHighlightBase,
        onTap: () => _showSheet(
          context,
          '功能模式',
          functionModeOptions,
          selectedAction,
          c.updateAction,
        ),
      ),
      const SizedBox(height: AppDimens.gapM),
      if (_shouldShowMode(state))
        CellButtonWidget(
          title: '模式',
          buttonText: state.mode,
          active: state.mode == '触发',
          onPressed: () => c.updateMode(_toggleMode(state.mode)),
        ),
      if (_shouldShowMode(state)) const SizedBox(height: AppDimens.gapM),
      if (_shouldShowCh5SwitchOptions(state)) ...[
        CellIconTextWidget(
          title: '功能:向前',
          valueText: state.mixingMode1 ?? '未设置',
          enableHighlight: true,
          highlightGradient: AppGradients.v24,
          highlightBaseColor: _mappingCellHighlightBase,
          onTap: () => _showSheet(
            context,
            '功能:向前',
            ch5DirectionOptionsList,
            ch5DirectionOptionsList.contains(state.mixingMode1)
                ? state.mixingMode1
                : null,
            (v) => c.updateMixingMode(1, v),
          ),
        ),
        const SizedBox(height: AppDimens.gapM),
        CellIconTextWidget(
          title: '功能:向中',
          valueText: state.mixingMode2 ?? '未设置',
          enableHighlight: true,
          highlightGradient: AppGradients.v24,
          highlightBaseColor: _mappingCellHighlightBase,
          onTap: () => _showSheet(
            context,
            '功能:向中',
            ch5DirectionOptionsList,
            ch5DirectionOptionsList.contains(state.mixingMode2)
                ? state.mixingMode2
                : null,
            (v) => c.updateMixingMode(2, v),
          ),
        ),
        const SizedBox(height: AppDimens.gapM),
        CellIconTextWidget(
          title: '功能:向后',
          valueText: state.mixingMode3 ?? '未设置',
          enableHighlight: true,
          highlightGradient: AppGradients.v24,
          highlightBaseColor: _mappingCellHighlightBase,
          onTap: () => _showSheet(
            context,
            '功能:向后',
            ch5DirectionOptionsList,
            ch5DirectionOptionsList.contains(state.mixingMode3)
                ? state.mixingMode3
                : null,
            (v) => c.updateMixingMode(3, v),
          ),
        ),
        const SizedBox(height: AppDimens.gapM),
      ],
    ];
  }

  void _showSheet(
    BuildContext context,
    String title,
    List<String> options,
    String? selectedOption,
    ValueChanged<String> onOptionSelected,
  ) {
    AlertSelectionSheet.show(
      context,
      title: title,
      options: options,
      selectedOption: selectedOption,
      titleFontWeight: AppFonts.w700,
      onOptionSelected: onOptionSelected,
    );
  }

  bool _shouldShowMode(ControlMappingState state) {
    return state.type == '单击';
  }

  String _toggleMode(String mode) {
    return mode == '触发' ? '翻转' : '触发';
  }

  bool _shouldShowCh5SwitchOptions(ControlMappingState state) {
    return isCh5ThreeWaySwitch(state.channel, state.type) &&
        isCh5MixingAction(state.action);
  }

  String _ch5MixingFunctionByAction(ControlMappingState state) {
    if (state.action == '驱动混控') return '混动';
    if (state.action == '四轮混控') return '四轮';
    return state.mixingFunction ?? ch5MixingFunctionOptions.first;
  }

  Widget _channelHeader(String channel) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEDF5FF), Color(0xFF92C3FF)],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        channel.toUpperCase(),
        style: AppTextStyles.controlMappingHeader,
      ),
    );
  }
}

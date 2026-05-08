import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';
import 'package:rc_configurator_flutter/l10n/app_localizations.dart';
import '../../provider/control_mapping_labels.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
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
            child: _channelHeader('${state.channel} ${l10n.control}'),
          ),
        ],
      ),
      const SizedBox(height: AppDimens.gapL),
      CellIconTextWidget(
        title: l10n.type,
        valueText: state.type.isEmpty
            ? l10n.notSet
            : ControlMappingLabels.displayLabel(state.type, locale),
        enableHighlight: true,
        highlightGradient: AppGradients.v24,
        highlightBaseColor: _mappingCellHighlightBase,
        onTap: () => _showSheet(
          context,
          l10n.type,
          state.availableStates,
          state.type.isEmpty ? null : state.type,
          c.updateType,
        ),
      ),
      const SizedBox(height: AppDimens.gapM),
      CellIconTextWidget(
        title: l10n.functionMode,
        valueText: state.action.isEmpty
            ? l10n.notSet
            : ControlMappingLabels.displayLabel(state.action, locale),
        enableHighlight: true,
        highlightGradient: AppGradients.v24,
        highlightBaseColor: _mappingCellHighlightBase,
        onTap: () => _showSheet(
          context,
          l10n.functionMode,
          functionModeOptions,
          selectedAction,
          (v) => _onActionSelected(context, c, v),
        ),
      ),
      const SizedBox(height: AppDimens.gapM),
      if (_shouldShowMode(state))
        CellButtonWidget(
          title: l10n.mode,
          buttonText: ControlMappingLabels.displayLabel(state.mode, locale),
          active: state.mode == 'Trigger',
          onPressed: () => c.updateMode(_toggleMode(state.mode)),
        ),
      if (_shouldShowMode(state)) const SizedBox(height: AppDimens.gapM),
      if (_shouldShowCh5SwitchOptions(state)) ...[
        CellIconTextWidget(
          title: l10n.functionForward,
          valueText: state.mixingMode3 != null
              ? ControlMappingLabels.displayLabel(state.mixingMode3!, locale)
              : l10n.notSet,
          enableHighlight: true,
          highlightGradient: AppGradients.v24,
          highlightBaseColor: _mappingCellHighlightBase,
          onTap: () => _showSheet(
            context,
            l10n.functionForward,
            ch5DirectionOptionsList,
            ch5DirectionOptionsList.contains(state.mixingMode3)
                ? state.mixingMode3
                : null,
            (v) => c.updateMixingMode(3, v),
          ),
        ),
        const SizedBox(height: AppDimens.gapM),
        CellIconTextWidget(
          title: l10n.functionCenter,
          valueText: state.mixingMode2 != null
              ? ControlMappingLabels.displayLabel(state.mixingMode2!, locale)
              : l10n.notSet,
          enableHighlight: true,
          highlightGradient: AppGradients.v24,
          highlightBaseColor: _mappingCellHighlightBase,
          onTap: () => _showSheet(
            context,
            l10n.functionCenter,
            ch5DirectionOptionsList,
            ch5DirectionOptionsList.contains(state.mixingMode2)
                ? state.mixingMode2
                : null,
            (v) => c.updateMixingMode(2, v),
          ),
        ),
        const SizedBox(height: AppDimens.gapM),
        CellIconTextWidget(
          title: l10n.functionBackward,
          valueText: state.mixingMode1 != null
              ? ControlMappingLabels.displayLabel(state.mixingMode1!, locale)
              : l10n.notSet,
          enableHighlight: true,
          highlightGradient: AppGradients.v24,
          highlightBaseColor: _mappingCellHighlightBase,
          onTap: () => _showSheet(
            context,
            l10n.functionBackward,
            ch5DirectionOptionsList,
            ch5DirectionOptionsList.contains(state.mixingMode1)
                ? state.mixingMode1
                : null,
            (v) => c.updateMixingMode(1, v),
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
    final locale = Localizations.localeOf(context);
    final displayOptions = options
        .map((o) => ControlMappingLabels.displayLabel(o, locale))
        .toList();
    final selectedDisplay = (selectedOption != null && selectedOption.isNotEmpty)
        ? ControlMappingLabels.displayLabel(selectedOption, locale)
        : null;
    AlertSelectionSheet.show(
      context,
      title: title,
      options: displayOptions,
      selectedOption: selectedDisplay,
      titleFontWeight: AppFonts.w700,
      onOptionSelected: (v) {
        final internalValue = ControlMappingLabels.internalId(v, locale);
        onOptionSelected(internalValue);
      },
    );
  }

  void _onActionSelected(
    BuildContext context,
    ControlMappingController controller,
    String action,
  ) {
    final duplicateChannel = controller.duplicateActionOwner(action);
    if (duplicateChannel == null) {
      controller.updateAction(action);
      return;
    }
    unawaited(
      _confirmDuplicateAction(context, controller, action, duplicateChannel),
    );
  }

  Future<void> _confirmDuplicateAction(
    BuildContext context,
    ControlMappingController controller,
    String action,
    String duplicateChannel,
  ) async {
    await Future<void>.delayed(Duration.zero);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AlertIconWidget.show(
      context,
      title: l10n.duplicateTitle,
      message: l10n.duplicateAssignWarning,
      cancelText: l10n.cancel,
      confirmText: l10n.ok,
    );
    if (confirmed == true) {
      controller.updateActionResolvingDuplicate(action, duplicateChannel);
    }
  }

  bool _shouldShowMode(ControlMappingState state) {
    return state.channel != 'CH10' && state.type == 'Click';
  }

  String _toggleMode(String mode) {
    return mode == 'Trigger' ? 'Flip' : 'Trigger';
  }

  bool _shouldShowCh5SwitchOptions(ControlMappingState state) {
    return isCh5ThreeWaySwitch(state.channel, state.type) &&
        isCh5MixingAction(state.action);
  }

  String _ch5MixingFunctionByAction(ControlMappingState state) {
    if (state.action == 'Drive Mix') return 'Hybrid';
    if (state.action == '4W Mix') return '4W';
    return state.mixingFunction ?? ch5MixingFunctionOptions.first;
  }

  Widget _channelHeader(String label) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEDF5FF), Color(0xFF92C3FF)],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.controlMappingHeader,
      ),
    );
  }
}

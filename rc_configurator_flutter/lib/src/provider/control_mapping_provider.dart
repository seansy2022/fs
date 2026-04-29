import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state_provider.dart';
import 'app_state_models.dart';
import 'control_mapping_mode_utils.dart';
import 'control_mapping_options.dart';

export 'app_state_models.dart' show ControlMappingState;

class ControlMappingController extends Notifier<ControlMappingState> {
  @override
  ControlMappingState build() {
    return ref.watch(
      rcAppStateProvider.select((state) => state.controlMapping),
    );
  }

  void selectChannel(String channel) {
    final appController = ref.container.read(rcAppStateProvider.notifier);
    appController.focusControlMappingChannel(channel);
    final cached = appController.state.controlMappings[channel];
    if (cached != null) {
      final type = normalizeControlTypeForChannel(channel, cached.type);
      _preview(_nextWithType(cached, type));
    } else {
      final types = controlTypeOptionsForChannel(channel);
      final base = initialControlMappingState().copyWith(channel: channel);
      _preview(_nextWithType(base, types.first));
    }
    unawaited(appController.refreshControlMappingForChannel(channel));
  }

  void updateType(String type) {
    _commit(_nextWithType(state, type));
  }

  void updateAction(String action) {
    _commit(_nextWithAction(state, action));
  }

  String? duplicateActionOwner(String action) {
    if (action == state.action || !_shouldCheckDuplicateAction(action)) {
      return null;
    }
    final mappings = ref.container.read(rcAppStateProvider).controlMappings;
    for (final channel in controlMappingChannels) {
      if (channel == state.channel) continue;
      if (mappings[channel]?.action == action) return channel;
    }
    return null;
  }

  void updateActionResolvingDuplicate(String action, String previousChannel) {
    final mappings = ref.container.read(rcAppStateProvider).controlMappings;
    final previous = mappings[previousChannel];
    if (previous == null) {
      updateAction(action);
      return;
    }
    _commitBatch([
      _nextWithAction(previous, controlMappingNoAction),
      _nextWithAction(state, action),
    ]);
  }

  void updateMode(String mode) {
    _commit(state.copyWith(mode: mode));
  }

  void updateMixingFunction(String mixingFunction) {
    final action = mixingFunction == '混动' ? '驱动混控' : '四轮混控';
    updateAction(action);
  }

  void updateTargetChannel(String? channel) {
    _commit(state.copyWith(targetChannel: channel));
  }

  void updateMixingMode(int index, String mode) {
    final slot = index - 1;
    if (slot < 0 || slot > 2) return;
    final modes = _normalizedModes(
      state,
      ch5DirectionOptions(state.mixingFunction),
      preferredIndex: slot,
      preferredValue: mode,
    );
    _commit(
      state.copyWith(
        mixingMode1: modes[0],
        mixingMode2: modes[1],
        mixingMode3: modes[2],
      ),
    );
  }

  ControlMappingState _nextWithType(ControlMappingState current, String type) {
    final channel = current.channel;
    final actions = functionModeOptionsForChannel(channel, type: type);
    final normalizedAction = actions.contains(current.action)
        ? current.action
        : _fallbackAction(channel, type, actions);
    final next = current.copyWith(
      type: type,
      selectedState: type,
      controlType: controlTypeForSelection(channel, type),
      availableStates: controlTypeOptionsForChannel(channel),
      mode: type == '单击' ? (current.mode.isEmpty ? '翻转' : current.mode) : '',
      action: normalizedAction,
      functionType: normalizedAction,
      targetChannel: isChannelFunctionMode(normalizedAction)
          ? normalizedAction
          : null,
    );
    if (!isCh5ThreeWaySwitch(channel, type)) {
      return next.copyWith(
        mixingFunction: null,
        mixingMode1: null,
        mixingMode2: null,
        mixingMode3: null,
      );
    }
    final action = normalizedAction.isEmpty
        ? _fallbackAction(channel, type, actions)
        : normalizedAction;
    if (isChannelFunctionMode(action)) {
      return next.copyWith(
        action: action,
        functionType: action,
        targetChannel: action,
        mixingFunction: null,
        mixingMode1: null,
        mixingMode2: null,
        mixingMode3: null,
      );
    }
    if (isNoFunctionMode(action)) return _withoutMixingModes(next);
    final mixingFunction = _ch5MixingFunctionForAction(
      action,
      fallback: current.mixingFunction,
    );
    final options = ch5DirectionOptions(mixingFunction);
    final base = next.copyWith(
      action: action,
      functionType: action,
      targetChannel: null,
      mixingFunction: mixingFunction,
    );
    final modes = _normalizedModes(base, options);
    return base.copyWith(
      mixingFunction: mixingFunction,
      mixingMode1: modes[0],
      mixingMode2: modes[1],
      mixingMode3: modes[2],
    );
  }

  ControlMappingState _nextWithAction(
    ControlMappingState current,
    String action,
  ) {
    if (isCh5ThreeWaySwitch(current.channel, current.type)) {
      return _nextCh5Action(current, action);
    }
    final next = current.copyWith(
      action: action,
      functionType: action,
      targetChannel: isChannelFunctionMode(action) ? action : null,
    );
    return isNoFunctionMode(action) ? _withoutMixingModes(next) : next;
  }

  ControlMappingState _nextCh5Action(
    ControlMappingState current,
    String action,
  ) {
    final actions = functionModeOptionsForChannel(
      current.channel,
      type: current.type,
    );
    final normalizedAction = actions.contains(action)
        ? action
        : _fallbackAction(current.channel, current.type, actions);
    if (isChannelFunctionMode(normalizedAction)) {
      return _clearMixingModes(
        current.copyWith(
          action: normalizedAction,
          functionType: normalizedAction,
          targetChannel: normalizedAction,
        ),
      );
    }
    if (isNoFunctionMode(normalizedAction)) {
      return _withoutMixingModes(current.copyWith(action: normalizedAction));
    }
    return _nextCh5MixingAction(current, normalizedAction);
  }

  ControlMappingState _nextCh5MixingAction(
    ControlMappingState current,
    String action,
  ) {
    final mixingFunction = _ch5MixingFunctionForAction(
      action,
      fallback: current.mixingFunction,
    );
    final modes = _normalizedModes(
      current,
      ch5DirectionOptions(mixingFunction),
    );
    return current.copyWith(
      action: action,
      functionType: action,
      targetChannel: null,
      mixingFunction: mixingFunction,
      mixingMode1: modes[0],
      mixingMode2: modes[1],
      mixingMode3: modes[2],
    );
  }

  ControlMappingState _withoutMixingModes(ControlMappingState current) {
    return _clearMixingModes(
      current.copyWith(functionType: current.action, targetChannel: null),
    );
  }

  ControlMappingState _clearMixingModes(ControlMappingState current) {
    return current.copyWith(
      mixingFunction: null,
      mixingMode1: null,
      mixingMode2: null,
      mixingMode3: null,
    );
  }

  String _fallbackAction(String channel, String type, List<String> actions) {
    if (actions.isEmpty) return '';
    if (channel == 'CH5' && type == '旋钮' && actions.contains('CH5')) {
      return 'CH5';
    }
    if (channel == 'CH6' && type == '三档' && actions.contains('CH6')) {
      return 'CH6';
    }
    if (channel == 'CH10' && type == '二档' && actions.contains('CH10')) {
      return 'CH10';
    }
    if (channel == 'CH5' && type == '三档开关' && actions.contains('四轮混控')) {
      return '四轮混控';
    }
    return '';
  }

  String _ch5MixingFunctionForAction(String action, {String? fallback}) {
    if (action == '驱动混控') return '混动';
    if (action == '四轮混控') return '四轮';
    if (fallback != null && ch5MixingFunctionOptions.contains(fallback)) {
      return fallback;
    }
    return ch5MixingFunctionOptions.first;
  }

  List<String> _normalizedModes(
    ControlMappingState current,
    List<String> options, {
    int? preferredIndex,
    String? preferredValue,
  }) {
    return normalizeDistinctModes(
      [current.mixingMode1, current.mixingMode2, current.mixingMode3],
      options,
      preferredIndex: preferredIndex,
      preferredValue: preferredValue,
    );
  }

  void _commit(ControlMappingState next) {
    ref.container
        .read(rcAppStateProvider.notifier)
        .dispatch(ControlMappingUpdatedIntent(next));
  }

  void _commitBatch(List<ControlMappingState> next) {
    ref.container
        .read(rcAppStateProvider.notifier)
        .dispatch(ControlMappingBatchUpdatedIntent(next));
  }

  void _preview(ControlMappingState next) {
    ref.container
        .read(rcAppStateProvider.notifier)
        .dispatch(ControlMappingPreviewIntent(next));
  }

  bool _shouldCheckDuplicateAction(String action) {
    return action.isNotEmpty && !isNoFunctionMode(action);
  }
}

final controlMappingProvider =
    NotifierProvider<ControlMappingController, ControlMappingState>(
      ControlMappingController.new,
    );

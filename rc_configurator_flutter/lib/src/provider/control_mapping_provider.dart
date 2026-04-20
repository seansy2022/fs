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
    if (isCh5ThreeWaySwitch(state.channel, state.type)) {
      final actions = functionModeOptionsForChannel(
        state.channel,
        type: state.type,
      );
      final normalizedAction = actions.contains(action)
          ? action
          : _fallbackAction(state.channel, state.type, actions);
      if (isChannelFunctionMode(normalizedAction)) {
        _commit(
          state.copyWith(
            action: normalizedAction,
            functionType: normalizedAction,
            targetChannel: normalizedAction,
            mixingFunction: null,
            mixingMode1: null,
            mixingMode2: null,
            mixingMode3: null,
          ),
        );
        return;
      }
      final mixingFunction = _ch5MixingFunctionForAction(
        normalizedAction,
        fallback: state.mixingFunction,
      );
      final modes = _normalizedModes(
        state,
        ch5DirectionOptions(mixingFunction),
      );
      _commit(
        state.copyWith(
          action: normalizedAction,
          functionType: normalizedAction,
          targetChannel: null,
          mixingFunction: mixingFunction,
          mixingMode1: modes[0],
          mixingMode2: modes[1],
          mixingMode3: modes[2],
        ),
      );
      return;
    }
    _commit(
      state.copyWith(
        action: action,
        functionType: action,
        targetChannel: isChannelFunctionMode(action) ? action : null,
      ),
    );
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

  String _fallbackAction(String channel, String type, List<String> actions) {
    if (actions.isEmpty) return '';
    if (channel == 'CH5' && type == '旋钮' && actions.contains('CH5')) {
      return 'CH5';
    }
    if (channel == 'CH6' && type == '三档' && actions.contains('CH6')) {
      return 'CH6';
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

  void _preview(ControlMappingState next) {
    ref.container
        .read(rcAppStateProvider.notifier)
        .dispatch(ControlMappingPreviewIntent(next));
  }
}

final controlMappingProvider =
    NotifierProvider<ControlMappingController, ControlMappingState>(
      ControlMappingController.new,
    );

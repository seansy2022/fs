import 'app_state_models.dart';
import 'control_mapping_reset_config.dart';
import 'control_mapping_options.dart';

const _resetMode = 'Flip';
const _resetMixingMode = '4WS';

List<ControlMappingState> controlMappingResetDefaults() {
  return controlMappingResetConfigs
      .map(_defaultFromConfig)
      .toList(growable: false);
}

ControlMappingState _defaultFromConfig(ControlMappingResetConfig config) {
  final channel = config.channel;
  final type = config.type;
  final functionType = config.action;
  final action = functionType == 'Channel Output'
      ? config.targetChannel
      : functionType;
  return ControlMappingState(
    channel: channel,
    type: type,
    action: action,
    mode: _resetMode,
    controlType: controlTypeForSelection(channel, type),
    availableStates: controlTypeOptionsForChannel(channel),
    selectedState: type,
    functionType: functionType,
    targetChannel: config.targetChannel,
    mixingFunction: null,
    mixingMode1: _resetMixingMode,
    mixingMode2: _resetMixingMode,
    mixingMode3: _resetMixingMode,
  );
}

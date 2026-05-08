import '../types.dart';

const controlMappingChannels = <String>[
  'CH3',
  'CH4',
  'CH5',
  'CH6',
  'CH7',
  'CH8',
  'CH9',
  'CH10',
  'CH11',
];
const controlMappingNoAction = 'None';

const _buttonTypeOptions = <String>['Click', 'Double Click', 'Triple Click', 'Long Press'];
const _ch5TypeOptions = <String>['Knob', '3-Pos Switch'];
const _ch9TypeOptions = <String>['Knob'];
const _ch6TypeOptions = <String>['3-Pos'];
const _ch10TypeOptions = <String>['2-Pos'];
const _buttonFunctionModeOptions = <String>[
  ...controlMappingChannels,
  '4WS Mode Switch',
  'Drive Mix Toggle',
  controlMappingNoAction,
];
const _ch5FunctionModeOptions = <String>[
  ...controlMappingChannels,
  '4W Mix',
  'Drive Mix',
  controlMappingNoAction,
];
const _ch9FunctionModeOptions = <String>[
  ...controlMappingChannels,
  'Throttle Trim',
  'Steering Trim',
  '4WS Mix Ratio',
  'Drive Mix Forward Ratio',
  'Drive Mix Reverse Ratio',
  'Brake Mix Ratio',
  'Steering Ratio',
  'Forward Ratio',
  'Brake Ratio',
  controlMappingNoAction,
];
const _ch10FunctionModeOptions = <String>[
  ...controlMappingChannels,
  controlMappingNoAction,
];
const ch5MixingFunctionOptions = <String>['4W', 'Hybrid'];
const _ch5FourWheelOptions = <String>[
  '4WS Front',
  '4WS Rear',
  '4WS F/R Same',
  '4WS F/R Reverse',
];
const _ch5DriveOptions = <String>['Drive Mix Rear', 'Drive Mix F/R Hybrid', 'Drive Mix Front'];

List<String> controlTypeOptionsForChannel(String channel) {
  switch (channel) {
    case 'CH3':
    case 'CH4':
    case 'CH7':
    case 'CH8':
    case 'CH11':
      return _buttonTypeOptions;
    case 'CH5':
      return _ch5TypeOptions;
    case 'CH9':
      return _ch9TypeOptions;
    case 'CH6':
      return _ch6TypeOptions;
    case 'CH10':
      return _ch10TypeOptions;
    default:
      return _buttonTypeOptions;
  }
}

List<String> functionModeOptionsForChannel(String channel, {String? type}) {
  switch (channel) {
    case 'CH3':
    case 'CH4':
    case 'CH7':
    case 'CH8':
    case 'CH11':
      return _buttonFunctionModeOptions;
    case 'CH5':
      if (type == 'Knob' || type == 'None') {
        return const [...controlMappingChannels, controlMappingNoAction];
      }
      return _ch5FunctionModeOptions;
    case 'CH9':
      return _ch9FunctionModeOptions;
    case 'CH6':
      return _ch5FunctionModeOptions;
    case 'CH10':
      return _ch10FunctionModeOptions;
    default:
      return _buttonFunctionModeOptions;
  }
}

List<String> ch5DirectionOptions(String? mixingFunction) {
  return mixingFunction == 'Hybrid' ? _ch5DriveOptions : _ch5FourWheelOptions;
}

ControlType controlTypeForSelection(String channel, String type) {
  if (channel == 'CH5' && type == '3-Pos Switch') return ControlType.threeWaySwitch;
  if (channel == 'CH5' || channel == 'CH9') return ControlType.knob;
  if (channel == 'CH6') return ControlType.threeWaySwitch;
  if (channel == 'CH10') return ControlType.latchSwitch;
  return ControlType.button;
}

bool isCh5ThreeWaySwitch(String channel, String type) {
  if (channel == 'CH5') return type == '3-Pos Switch';
  if (channel == 'CH6') return type == '3-Pos';
  return false;
}

bool isCh5MixingAction(String action) {
  return action == '4W Mix' || action == 'Drive Mix';
}

bool isChannelFunctionMode(String functionMode) {
  return controlMappingChannels.contains(functionMode);
}

bool isNoFunctionMode(String functionMode) {
  return functionMode == controlMappingNoAction;
}

String normalizeControlTypeForChannel(String channel, String type) {
  final options = controlTypeOptionsForChannel(channel);
  return options.contains(type) ? type : options.first;
}

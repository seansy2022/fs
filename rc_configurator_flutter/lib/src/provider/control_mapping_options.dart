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
const controlMappingNoAction = '无';

const _buttonTypeOptions = <String>['单击', '双击', '三击', '长按'];
const _ch5TypeOptions = <String>['旋钮', '三档开关'];
const _ch9TypeOptions = <String>['旋钮'];
const _ch6TypeOptions = <String>['三档'];
const _ch10TypeOptions = <String>['二档'];
const _buttonFunctionModeOptions = <String>[
  ...controlMappingChannels,
  '四轮转向模式切换',
  '驱动混控切换',
  controlMappingNoAction,
];
const _ch5FunctionModeOptions = <String>[
  ...controlMappingChannels,
  '四轮混控',
  '驱动混控',
  controlMappingNoAction,
];
const _ch9FunctionModeOptions = <String>[
  ...controlMappingChannels,
  '油门微调',
  '方向微调',
  '四轮转向混控比率',
  '驱动混控前进比率',
  '驱动混控后退比率',
  '刹车混控比率',
  '方向比率',
  '前进比率',
  '刹车比率',
  controlMappingNoAction,
];
const _ch10FunctionModeOptions = <String>[
  ...controlMappingChannels,
  controlMappingNoAction,
];
const ch5MixingFunctionOptions = <String>['四轮', '混动'];
const _ch5FourWheelOptions = <String>[
  '四轮转向前面',
  '四轮转向后面',
  '四轮转向前后同向',
  '四轮转向前后反向',
];
const _ch5DriveOptions = <String>['驱动混控前面', '驱动混控后面', '驱动混控前后混控'];

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
      if (type == '旋钮' || type == '无') {
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
  return mixingFunction == '混动' ? _ch5DriveOptions : _ch5FourWheelOptions;
}

ControlType controlTypeForSelection(String channel, String type) {
  if (channel == 'CH5' && type == '三档开关') return ControlType.threeWaySwitch;
  if (channel == 'CH5' || channel == 'CH9') return ControlType.knob;
  if (channel == 'CH6') return ControlType.threeWaySwitch;
  if (channel == 'CH10') return ControlType.latchSwitch;
  return ControlType.button;
}

bool isCh5ThreeWaySwitch(String channel, String type) {
  if (channel == 'CH5') return type == '三档开关';
  if (channel == 'CH6') return type == '三档';
  return false;
}

bool isCh5MixingAction(String action) {
  return action == '四轮混控' || action == '驱动混控';
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

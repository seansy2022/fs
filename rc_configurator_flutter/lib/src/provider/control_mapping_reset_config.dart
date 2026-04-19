class ControlMappingResetConfig {
  const ControlMappingResetConfig({
    required this.channel,
    required this.type,
    required this.action,
    required this.mode,
    required this.targetChannel,
    required this.payload,
  });

  final String channel;
  final String type;
  final String action;
  final String mode;
  final String targetChannel;
  final List<int> payload;
}

const _defaultAction = '通道输出';
const _defaultMode = '翻转';
const _singleClick = '单击';
const _noneType = '无';

const controlMappingResetSeedPayloads = <List<int>>[
  <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
  <int>[0, 1, 0, 0, 0, 0, 0, 0, 1],
];

const controlMappingResetConfigs = <ControlMappingResetConfig>[
  ControlMappingResetConfig(
    channel: 'CH3',
    type: _singleClick,
    action: _defaultAction,
    mode: _defaultMode,
    targetChannel: 'CH3',
    payload: <int>[0, 2, 1, 0, 0, 0, 0, 0, 2],
  ),
  ControlMappingResetConfig(
    channel: 'CH4',
    type: _singleClick,
    action: _defaultAction,
    mode: _defaultMode,
    targetChannel: 'CH4',
    payload: <int>[0, 3, 1, 0, 0, 0, 0, 0, 3],
  ),
  ControlMappingResetConfig(
    channel: 'CH5',
    type: _noneType,
    action: _defaultAction,
    mode: _defaultMode,
    targetChannel: 'CH5',
    payload: <int>[0, 4, 0, 0, 0, 0, 0, 0, 4],
  ),
  ControlMappingResetConfig(
    channel: 'CH6',
    type: _noneType,
    action: _defaultAction,
    mode: _defaultMode,
    targetChannel: 'CH6',
    payload: <int>[0, 5, 0, 0, 0, 0, 0, 0, 5],
  ),
  ControlMappingResetConfig(
    channel: 'CH7',
    type: _singleClick,
    action: _defaultAction,
    mode: _defaultMode,
    targetChannel: 'CH7',
    payload: <int>[0, 6, 1, 0, 0, 0, 0, 0, 6],
  ),
  ControlMappingResetConfig(
    channel: 'CH8',
    type: _singleClick,
    action: _defaultAction,
    mode: _defaultMode,
    targetChannel: 'CH8',
    payload: <int>[0, 7, 1, 0, 0, 0, 0, 0, 7],
  ),
  ControlMappingResetConfig(
    channel: 'CH9',
    type: _noneType,
    action: _defaultAction,
    mode: _defaultMode,
    targetChannel: 'CH9',
    payload: <int>[0, 8, 0, 0, 0, 0, 0, 0, 8],
  ),
  ControlMappingResetConfig(
    channel: 'CH10',
    type: _singleClick,
    action: _defaultAction,
    mode: _defaultMode,
    targetChannel: 'CH10',
    payload: <int>[0, 9, 1, 0, 0, 0, 0, 0, 9],
  ),
  ControlMappingResetConfig(
    channel: 'CH11',
    type: _singleClick,
    action: _defaultAction,
    mode: _defaultMode,
    targetChannel: 'CH11',
    payload: <int>[0, 10, 1, 0, 0, 0, 0, 0, 10],
  ),
];

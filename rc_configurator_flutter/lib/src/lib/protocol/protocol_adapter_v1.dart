import 'dart:math';

import 'package:rc_ble/rc_ble.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/control_mapping_action_code_config.dart';
import 'package:rc_configurator_flutter/src/provider/control_mapping_options.dart';
import 'package:rc_configurator_flutter/src/types.dart';
import 'protocol_adapter.dart';

class ProtocolAdapterV1 implements ProtocolAdapter {
  static const _channelCount = 11;
  static const _rawSpikeThreshold = 250;
  static const _jumpConfirmFrames = 3;
  static const _smoothWindowSize = 5;
  final List<int?> _stableChannelRaw = List<int?>.filled(_channelCount, null);
  final List<int?> _pendingChannelRaw = List<int?>.filled(_channelCount, null);
  final List<int> _pendingChannelRawCount = List<int>.filled(_channelCount, 0);
  final List<List<int>> _smoothWindows = List<List<int>>.generate(
    _channelCount,
    (_) => <int>[],
  );

  @override
  BluetoothFrame encodeRead({
    required int seq,
    required BluetoothCommand command,
  }) {
    return buildReadFrame(seq: seq, command: command);
  }

  @override
  BluetoothFrame encodeWrite({
    required int seq,
    required BluetoothCommand command,
    required List<int> payload,
  }) {
    return buildWriteFrame(seq: seq, command: command, payload: payload);
  }

  @override
  ProtocolFrameEvent decodeFrame(BluetoothFrame frame) {
    return ProtocolFrameEvent(
      frame: frame,
      command: BluetoothCommand.fromId(frame.command),
      ack: parseAck(frame),
      channelSnapshot: parseChannelDisplay(frame),
      telemetryPacket: parseTelemetryDisplay(frame),
      passthroughPacket: parsePassthrough(frame),
    );
  }

  @override
  RcAppState applyToState(RcAppState state, ProtocolFrameEvent event) {
    final payload = _trimPayload(event.frame);
    if (_isConfigAckFrame(event.command, payload)) return state;
    final raw = Map<int, List<int>>.from(state.protocol.rawPayloadByCommand);
    raw[event.frame.command] = payload;
    var next = state.copyWith(
      protocol: state.protocol.copyWith(rawPayloadByCommand: raw),
    );
    final cmd = event.command;
    if (cmd == null) return next;
    return switch (cmd) {
      BluetoothCommand.channelReverse => _applyChannelReverse(next, payload),
      BluetoothCommand.channelTravel => _applyChannelTravel(next, payload),
      BluetoothCommand.subTrim => _applySubTrim(next, payload),
      BluetoothCommand.dualRate => _applyDualRate(next, payload),
      BluetoothCommand.curve => _applyCurve(next, payload),
      BluetoothCommand.fourWheelSteer => _applyFourWheelSteer(next, payload),
      BluetoothCommand.failsafe => _applyFailsafe(next, payload),
      BluetoothCommand.escSetting => _applyEscSetting(next, payload),
      BluetoothCommand.modelSwitch => _applyModelSwitch(next, payload),
      BluetoothCommand.trackMixing => _applyTrackMixing(next, payload),
      BluetoothCommand.driveMixing => _applyDriveMixing(next, payload),
      BluetoothCommand.brakeMixing => _applyBrakeMixing(next, payload),
      BluetoothCommand.controlMapping => _applyControlMapping(next, payload),
      BluetoothCommand.systemSetting => _applySystemSetting(next, payload),
      BluetoothCommand.channelDisplay => _applyChannelDisplay(next, event),
      BluetoothCommand.telemetryDisplay => _applyTelemetry(next, event),
      BluetoothCommand.passthrough => next,
    };
  }

  bool _isConfigAckFrame(BluetoothCommand? command, List<int> payload) {
    if (command == null || payload.length != 1) return false;
    final code = payload.first & 0xFF;
    if (code < 0x20 || code > 0x2F) return false;
    return command.id >= BluetoothCommand.channelReverse.id &&
        command.id <= BluetoothCommand.systemSetting.id;
  }

  @override
  Iterable<BluetoothCommand> startupReadCommands() {
    return const [
      BluetoothCommand.channelReverse,
      BluetoothCommand.channelTravel,
      BluetoothCommand.subTrim,
      BluetoothCommand.dualRate,
      BluetoothCommand.curve,
      BluetoothCommand.fourWheelSteer,
      BluetoothCommand.failsafe,
      BluetoothCommand.escSetting,
      BluetoothCommand.modelSwitch,
      BluetoothCommand.trackMixing,
      BluetoothCommand.driveMixing,
      BluetoothCommand.brakeMixing,
      BluetoothCommand.controlMapping,
      BluetoothCommand.systemSetting,
    ];
  }

  @override
  Iterable<BluetoothCommand> readCommandsForScreen(Screen screen) {
    switch (screen) {
      case Screen.channels:
        return const [BluetoothCommand.channelTravel];
      case Screen.reverse:
        return const [BluetoothCommand.channelReverse];
      case Screen.subTrim:
        return const [BluetoothCommand.subTrim];
      case Screen.dualRate:
        return const [BluetoothCommand.dualRate];
      case Screen.curve:
        return const [BluetoothCommand.curve];
      case Screen.controlMapping:
        return const [BluetoothCommand.controlMapping];
      case Screen.modelSelection:
        return const [BluetoothCommand.modelSwitch];
      case Screen.failsafe:
        return const [BluetoothCommand.failsafe];
      case Screen.radioSettings:
        return const [BluetoothCommand.systemSetting];
      case Screen.mixing:
        return const [
          BluetoothCommand.fourWheelSteer,
          BluetoothCommand.trackMixing,
          BluetoothCommand.driveMixing,
          BluetoothCommand.brakeMixing,
        ];
      case Screen.dashboard:
      case Screen.functions:
      case Screen.bluetooth:
        return const <BluetoothCommand>[];
    }
  }

  @override
  List<ProtocolWriteRequest> writesForIntent(
    RcAppIntent intent,
    RcAppState state,
  ) {
    if (intent is DualRateUpdatedIntent) {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.dualRate,
          payload: _buildDualRatePayload(state.channels),
        ),
      ];
    }
    if (intent is ChannelTravelUpdatedIntent) {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.channelTravel,
          payload: _buildTravelPayload(state.channels),
        ),
      ];
    }
    if (intent is ChannelReverseUpdatedIntent) {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.channelReverse,
          payload: _buildReversePayload(state.channels),
        ),
      ];
    }
    if (intent is SubTrimUpdatedIntent) {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.subTrim,
          payload: _buildSubTrimPayload(state.channels),
        ),
      ];
    }
    if (intent is FailsafeUpdatedIntent) {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.failsafe,
          payload: _buildFailsafePayload(state.channels),
        ),
      ];
    }
    if (intent is ChannelUpdatedIntent) {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.channelReverse,
          payload: _buildReversePayload(state.channels),
        ),
        ProtocolWriteRequest(
          command: BluetoothCommand.channelTravel,
          payload: _buildTravelPayload(state.channels),
        ),
        ProtocolWriteRequest(
          command: BluetoothCommand.subTrim,
          payload: _buildSubTrimPayload(state.channels),
        ),
        ProtocolWriteRequest(
          command: BluetoothCommand.dualRate,
          payload: _buildDualRatePayload(state.channels),
        ),
        ProtocolWriteRequest(
          command: BluetoothCommand.failsafe,
          payload: _buildFailsafePayload(state.channels),
        ),
      ];
    }
    if (intent is ModelSelectedIntent) {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.modelSwitch,
          payload: _buildModelSwitchPayload(state.models),
        ),
      ];
    }
    if (intent is RadioSettingsUpdatedIntent) {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.systemSetting,
          payload: _buildSystemSettingPayload(state.radioSettings),
        ),
      ];
    }
    if (intent is MixingSettingsUpdatedIntent) {
      return _buildMixingRequests(state);
    }
    if (intent is CurveValueUpdatedIntent || intent is CurveSelectedIntent) {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.curve,
          payload: _buildCurvePayload(state),
        ),
      ];
    }
    if (intent is ControlMappingUpdatedIntent) {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.controlMapping,
          payload: _buildControlMappingPayload(state.controlMapping),
        ),
      ];
    }
    return const [];
  }

  RcAppState _applyChannelDisplay(RcAppState state, ProtocolFrameEvent event) {
    final packet = event.channelSnapshot;
    if (packet == null) return state;
    final channels = [...state.channels];
    for (var i = 0; i < min(channels.length, packet.values.length); i++) {
      final filteredRaw = _filterChannelRaw(i, packet.values[i]);
      final smoothRaw = _smoothChannelRaw(i, filteredRaw);
      final value = ((smoothRaw - 1500) / 500 * 100).round().clamp(-120, 120);
      channels[i] = channels[i].copyWith(value: value);
    }
    return state.copyWith(channels: channels);
  }

  int _filterChannelRaw(int index, int raw) {
    final stable = _stableChannelRaw[index];
    if (stable == null) {
      _acceptStable(index, raw);
      return raw;
    }
    if ((raw - stable).abs() <= _rawSpikeThreshold) {
      _acceptStable(index, raw);
      return raw;
    }
    final pending = _pendingChannelRaw[index];
    if (pending != null && (raw - pending).abs() <= _rawSpikeThreshold) {
      final nextCount = _pendingChannelRawCount[index] + 1;
      _pendingChannelRawCount[index] = nextCount;
      if (nextCount >= _jumpConfirmFrames) {
        _acceptStable(index, raw);
        return raw;
      }
      return stable;
    }
    _pendingChannelRaw[index] = raw;
    _pendingChannelRawCount[index] = 1;
    return stable;
  }

  void _acceptStable(int index, int raw) {
    _stableChannelRaw[index] = raw;
    _pendingChannelRaw[index] = null;
    _pendingChannelRawCount[index] = 0;
  }

  int _smoothChannelRaw(int index, int raw) {
    final window = _smoothWindows[index];
    window.add(raw);
    if (window.length > _smoothWindowSize) {
      window.removeAt(0);
    }
    if (window.length < 3) return raw;
    final sorted = [...window]..sort();
    if (sorted.length < _smoothWindowSize) {
      return sorted[sorted.length ~/ 2];
    }
    final middle = sorted.sublist(1, sorted.length - 1);
    final sum = middle.fold<int>(0, (acc, v) => acc + v);
    return (sum / middle.length).round();
  }

  RcAppState _applyTelemetry(RcAppState state, ProtocolFrameEvent event) {
    final packet = event.telemetryPacket;
    if (packet == null || packet.values.isEmpty) return state;
    final values = packet.values;
    final tx = values.isNotEmpty ? _decodeVoltage(values[0].rawValue) : null;
    final rx = values.length > 1 ? _decodeVoltage(values[1].rawValue) : null;
    final rssi = values.length > 2 ? _decodeRssi(values[2].rawValue) ?? 0 : 0;
    return state.copyWith(
      telemetry: state.telemetry.copyWith(
        txVoltage: tx,
        rxVoltage: rx,
        signalStrength: rssi,
      ),
    );
  }

  double? _decodeVoltage(int raw) {
    if (raw < 35 || raw > 900) return null;
    return raw / 10.0;
  }

  int? _decodeRssi(int raw) {
    if (raw < 1 || raw > 100) return null;
    return -raw;
  }

  RcAppState _applyChannelReverse(RcAppState state, List<int> payload) {
    final channels = [...state.channels];
    for (var i = 0; i < min(channels.length, min(payload.length, 11)); i++) {
      channels[i] = channels[i].copyWith(reverse: payload[i] == 1);
    }
    return state.copyWith(channels: channels);
  }

  RcAppState _applyChannelTravel(RcAppState state, List<int> payload) {
    final channels = [...state.channels];
    for (var i = 0; i < min(channels.length, 11); i++) {
      final idx = i * 2;
      if (idx + 1 >= payload.length) break;
      channels[i] = channels[i].copyWith(
        lLimit: payload[idx].clamp(0, 120),
        rLimit: payload[idx + 1].clamp(0, 120),
      );
    }
    return state.copyWith(channels: channels);
  }

  RcAppState _applySubTrim(RcAppState state, List<int> payload) {
    final channels = [...state.channels];
    for (var i = 0; i < min(channels.length, 11); i++) {
      final idx = i * 2;
      if (idx + 1 >= payload.length) break;
      final value = _int16(payload[idx], payload[idx + 1]).clamp(-240, 240);
      channels[i] = channels[i].copyWith(offset: value);
    }
    return state.copyWith(channels: channels);
  }

  RcAppState _applyDualRate(RcAppState state, List<int> payload) {
    final channels = [...state.channels];
    if (channels.isEmpty) return state;
    if (payload.isNotEmpty) {
      channels[0] = channels[0].copyWith(dualRate: payload[0].clamp(0, 100));
    }
    if (payload.length > 2 && channels.length > 1) {
      channels[1] = channels[1].copyWith(dualRate: payload[2].clamp(0, 100));
    }
    if (payload.length > 3 && channels.length > 2) {
      channels[2] = channels[2].copyWith(dualRate: payload[3].clamp(0, 100));
    }
    return state.copyWith(channels: channels);
  }

  RcAppState _applyCurve(RcAppState state, List<int> payload) {
    final values = [...state.protocol.curveValues];
    if (payload.isNotEmpty) values[0] = _int8(payload[0]);
    if (payload.length > 2) values[1] = _int8(payload[2]);
    if (payload.length > 3) values[2] = _int8(payload[3]);
    final active = state.curve.activeCurve;
    final current = switch (active) {
      'Steering' => values[0],
      'Forward' => values[1],
      'Brake' => values[2],
      _ => values[1],
    };
    return state.copyWith(
      curve: state.curve.copyWith(curveValue: current),
      protocol: state.protocol.copyWith(curveValues: values),
    );
  }

  RcAppState _applyFourWheelSteer(RcAppState state, List<int> payload) {
    if (payload.length < 4) return state;
    final enabled = payload[0] == 1;
    final mode = payload[3].clamp(0, 3);
    final ratio = payload[2].clamp(0, 100);
    final direction = switch (mode) {
      1 => '4WS_FRONT_OPPOSITE',
      2 => '4WS_REAR_SAME',
      3 => '4WS_REAR_OPPOSITE',
      _ => '4WS_FRONT_SAME',
    };
    final snap = state.protocol.fourWheelSteer.copyWith(
      enabled: enabled,
      channel: payload[1].clamp(2, 10),
      ratio: ratio,
      mode: mode,
    );
    var protocol = state.protocol.copyWith(fourWheelSteer: snap);
    if (snap.enabled) {
      protocol = _withOnlyMixingEnabled(protocol, '4WS');
    }
    return state.copyWith(
      mixingSettings: state.mixingSettings.copyWith(
        activeMode: enabled
            ? '4WS'
            : _clearModeIfDisabled(state.mixingSettings.activeMode, '4WS'),
        selectedChannel: _protocolChannelToUi(snap.channel),
        ratio: ratio,
        direction: direction,
      ),
      protocol: protocol,
    );
  }

  RcAppState _applyFailsafe(RcAppState state, List<int> payload) {
    final channels = [...state.channels];
    for (var i = 0; i < min(channels.length, min(payload.length, 11)); i++) {
      final raw = payload[i] & 0xFF;
      if (raw == 0x7F) {
        channels[i] = channels[i].copyWith(failsafeActive: false);
      } else {
        channels[i] = channels[i].copyWith(
          failsafeActive: true,
          failsafeValue: _int8(raw),
        );
      }
    }
    return state.copyWith(channels: channels);
  }

  RcAppState _applyEscSetting(RcAppState state, List<int> payload) {
    if (payload.length < 3) return state;
    return state.copyWith(
      protocol: state.protocol.copyWith(
        escSetting: state.protocol.escSetting.copyWith(
          runningMode: payload[0],
          batteryType: payload[1],
          dragBrake: payload[2],
          receiverType: payload.length > 3 ? payload[3] : 0,
        ),
      ),
    );
  }

  RcAppState _applyModelSwitch(RcAppState state, List<int> payload) {
    if (payload.isEmpty) return state;
    final idx = payload[0].clamp(0, state.models.length - 1);
    final models = state.models
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(active: entry.key == idx))
        .toList();
    return state.copyWith(models: models);
  }

  RcAppState _applyTrackMixing(RcAppState state, List<int> payload) {
    if (payload.length < 5) return state;
    final snap = state.protocol.trackMixing.copyWith(
      enabled: payload[0] == 1,
      forwardRatio: payload[1].clamp(0, 100),
      backwardRatio: payload[2].clamp(0, 100),
      leftRatio: payload[3].clamp(0, 100),
      rightRatio: payload[4].clamp(0, 100),
    );
    final focus = _trackFocus(snap);
    var protocol = state.protocol.copyWith(trackMixing: snap);
    if (snap.enabled) {
      protocol = _withOnlyMixingEnabled(protocol, 'TRACK');
    }
    return state.copyWith(
      mixingSettings: state.mixingSettings.copyWith(
        activeMode: snap.enabled
            ? 'TRACK'
            : _clearModeIfDisabled(state.mixingSettings.activeMode, 'TRACK'),
        ratio: focus.$1,
        direction: focus.$2,
      ),
      protocol: protocol,
    );
  }

  RcAppState _applyDriveMixing(RcAppState state, List<int> payload) {
    if (payload.length < 5) return state;
    final snap = state.protocol.driveMixing.copyWith(
      enabled: payload[0] == 1,
      channel: payload[1].clamp(2, 10),
      frontRatio: payload[2].clamp(0, 100),
      rearRatio: payload[3].clamp(0, 100),
      mode: payload[4].clamp(0, 2),
    );
    final ratio = snap.frontRatio == 100
        ? 100 - snap.rearRatio
        : snap.frontRatio - 100;
    final direction = snap.mode == 0
        ? 'REAR'
        : snap.mode == 1
        ? 'MIXED'
        : 'FRONT';
    var protocol = state.protocol.copyWith(driveMixing: snap);
    if (snap.enabled) {
      protocol = _withOnlyMixingEnabled(protocol, 'DRIVE');
    }
    return state.copyWith(
      mixingSettings: state.mixingSettings.copyWith(
        activeMode: snap.enabled
            ? 'DRIVE'
            : _clearModeIfDisabled(state.mixingSettings.activeMode, 'DRIVE'),
        selectedChannel: _protocolChannelToUi(snap.channel),
        ratio: ratio.clamp(-100, 100),
        direction: direction,
      ),
      protocol: protocol,
    );
  }

  RcAppState _applyBrakeMixing(RcAppState state, List<int> payload) {
    if (payload.length < 6) return state;
    final snap = _isBrakeReadPayloadWithoutMixingNo(payload)
        ? _parseBrakePayloadWithoutMixingNo(state, payload)
        : _parseBrakePayloadWithMixingNo(state, payload);
    var protocol = state.protocol.copyWith(brakeMixing: snap);
    if (snap.enabled) {
      protocol = _withOnlyMixingEnabled(protocol, 'BRAKE');
    }
    return state.copyWith(
      mixingSettings: state.mixingSettings.copyWith(
        activeMode: snap.enabled
            ? 'BRAKE'
            : _clearModeIfDisabled(state.mixingSettings.activeMode, 'BRAKE'),
        selectedChannel: _protocolChannelToUi(snap.channel),
        ratio: snap.ratio,
        curve: snap.curve,
      ),
      protocol: protocol,
    );
  }

  BrakeMixingSnapshot _parseBrakePayloadWithMixingNo(
    RcAppState state,
    List<int> payload,
  ) {
    return state.protocol.brakeMixing.copyWith(
      mixingNo: payload[0].clamp(0, 1),
      enabled: payload[1] == 1,
      channel: payload[2].clamp(2, 10),
      exponentEnabled: payload[3] == 1,
      ratio: _int8(payload[4]).clamp(0, 100),
      curve: _int8(payload[5]).clamp(-100, 100),
    );
  }

  BrakeMixingSnapshot _parseBrakePayloadWithoutMixingNo(
    RcAppState state,
    List<int> payload,
  ) {
    final idx = state.protocol.brakeMixing.mixingNo.clamp(0, 1) * 5;
    return state.protocol.brakeMixing.copyWith(
      enabled: payload[idx] == 1,
      channel: payload[idx + 1].clamp(2, 10),
      exponentEnabled: payload[idx + 2] == 1,
      ratio: _int8(payload[idx + 3]).clamp(0, 100),
      curve: _int8(payload[idx + 4]).clamp(-100, 100),
    );
  }

  bool _isBrakeReadPayloadWithoutMixingNo(List<int> payload) {
    if (payload.length < 10) return false;
    return _isValidBrakeGroup(payload, 0) && _isValidBrakeGroup(payload, 5);
  }

  bool _isValidBrakeGroup(List<int> payload, int start) {
    if (start + 4 >= payload.length) return false;
    final enabled = payload[start];
    final channel = payload[start + 1];
    final exponent = payload[start + 2];
    final ratio = _int8(payload[start + 3]);
    return (enabled == 0 || enabled == 1) &&
        channel >= 2 &&
        channel <= 10 &&
        (exponent == 0 || exponent == 1) &&
        ratio >= 0 &&
        ratio <= 100;
  }

  RcAppState _applyControlMapping(RcAppState state, List<int> payload) {
    if (payload.length < 9) return state;
    final channel = _controlChannel(
      payload[1],
      fallback: state.controlMapping.channel,
    );
    final base = _controlMappingBaseState(state, channel);
    if ((channel == 'CH5' || channel == 'CH6') &&
        _isCh5MixingPayload(payload[7], payload[8])) {
      final mixingFunction = _ch5MixingFunctionFromPayload(
        payload[7],
        payload[8],
      );
      final action = _ch5ActionText(payload[8], mixingFunction);
      final targetChannel = action == '通道分配'
          ? _functionChannel(payload[8])
          : null;
      final type = channel == 'CH6' ? '三档' : '三档开关';
      final states = controlTypeOptionsForChannel(channel);
      final next = base.copyWith(
        channel: channel,
        type: type,
        action: action,
        mode: payload[3] == 1 ? '触发' : '翻转',
        controlType: ControlType.threeWaySwitch,
        availableStates: states,
        selectedState: type,
        functionType: action,
        targetChannel: targetChannel,
        mixingFunction: mixingFunction,
        mixingMode1: _ch5MixingModeText(mixingFunction, payload[4]),
        mixingMode2: _ch5MixingModeText(mixingFunction, payload[5]),
        mixingMode3: _ch5MixingModeText(mixingFunction, payload[6]),
      );
      return _upsertControlMappingState(state, next);
    }
    final action = _controlActionText(payload[7], functionCode: payload[8]);
    final targetChannel = _functionChannel(payload[8]);
    final type = normalizeControlTypeForChannel(
      channel,
      _controlStateText(payload[2]),
    );
    final next = base.copyWith(
      channel: channel,
      type: type,
      action: action == '通道输出'
          ? (payload[8] == 25 ? '未设置' : (targetChannel ?? action))
          : action,
      mode: payload[3] == 1 ? '触发' : '翻转',
      controlType: controlTypeForSelection(channel, type),
      availableStates: controlTypeOptionsForChannel(channel),
      selectedState: type,
      functionType: action,
      targetChannel: targetChannel,
      mixingMode1: _mixingModeText(payload[4]),
      mixingMode2: _mixingModeText(payload[5]),
      mixingMode3: _mixingModeText(payload[6]),
    );
    return _upsertControlMappingState(state, next);
  }

  RcAppState _upsertControlMappingState(
    RcAppState state,
    ControlMappingState next,
  ) {
    final mappings = Map<String, ControlMappingState>.from(
      state.controlMappings,
    );
    mappings[next.channel] = next;
    return state.copyWith(controlMapping: next, controlMappings: mappings);
  }

  ControlMappingState _controlMappingBaseState(
    RcAppState state,
    String channel,
  ) {
    final cached = state.controlMappings[channel];
    if (cached != null) return cached;
    final options = controlTypeOptionsForChannel(channel);
    final type = options.first;
    return initialControlMappingState().copyWith(
      channel: channel,
      type: type,
      mode: type == '单击' ? '翻转' : '',
      controlType: controlTypeForSelection(channel, type),
      availableStates: options,
      selectedState: type,
      action: '',
      functionType: '',
      targetChannel: null,
      mixingFunction: null,
      mixingMode1: null,
      mixingMode2: null,
      mixingMode3: null,
    );
  }

  RcAppState _applySystemSetting(RcAppState state, List<int> payload) {
    if (payload.length < 4) return state;
    final idle = (payload[1] & 0xFF) | ((payload[2] & 0xFF) << 8);
    return state.copyWith(
      radioSettings: state.radioSettings.copyWith(
        backlightTime: payload[0].clamp(0, 99),
        idleAlarm: idle.clamp(10, 9999),
        atmosphereLight: payload[3] == 1,
      ),
    );
  }

  List<ProtocolWriteRequest> _buildMixingRequests(RcAppState state) {
    final mode = state.mixingSettings.activeMode;
    if (mode.isEmpty) return const [];
    if (state.mixingSettings.enabled) {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.fourWheelSteer,
          payload: _buildFourWheelSteerPayload(state),
        ),
        ProtocolWriteRequest(
          command: BluetoothCommand.trackMixing,
          payload: _buildTrackPayload(state),
        ),
        ProtocolWriteRequest(
          command: BluetoothCommand.driveMixing,
          payload: _buildDrivePayload(state),
        ),
        ProtocolWriteRequest(
          command: BluetoothCommand.brakeMixing,
          payload: _buildBrakePayload(state),
        ),
      ];
    }
    if (mode == '4WS') {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.fourWheelSteer,
          payload: _buildFourWheelSteerPayload(state),
        ),
      ];
    }
    if (mode == 'TRACK') {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.trackMixing,
          payload: _buildTrackPayload(state),
        ),
      ];
    }
    if (mode == 'DRIVE') {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.driveMixing,
          payload: _buildDrivePayload(state),
        ),
      ];
    }
    if (mode == 'BRAKE') {
      return [
        ProtocolWriteRequest(
          command: BluetoothCommand.brakeMixing,
          payload: _buildBrakePayload(state),
        ),
      ];
    }
    return const [];
  }

  List<int> _buildReversePayload(List<ChannelState> channels) {
    return channels.take(11).map((e) => e.reverse ? 1 : 0).toList();
  }

  List<int> _buildTravelPayload(List<ChannelState> channels) {
    final out = <int>[];
    for (final ch in channels.take(11)) {
      out.add(ch.lLimit.clamp(0, 120));
      out.add(ch.rLimit.clamp(0, 120));
    }
    return out;
  }

  List<int> _buildSubTrimPayload(List<ChannelState> channels) {
    final out = <int>[];
    for (final ch in channels.take(11)) {
      final v = ch.offset.clamp(-240, 240) & 0xFFFF;
      out.add(v & 0xFF);
      out.add((v >> 8) & 0xFF);
    }
    return out;
  }

  List<int> _buildDualRatePayload(List<ChannelState> channels) {
    final first = channels.isNotEmpty
        ? channels[0].dualRate.clamp(0, 100)
        : 100;
    final second = channels.length > 1
        ? channels[1].dualRate.clamp(0, 100)
        : 100;
    final third = channels.length > 2
        ? channels[2].dualRate.clamp(0, 100)
        : 100;
    return [first, 0, second, third];
  }

  List<int> _buildCurvePayload(RcAppState state) {
    final values = [...state.protocol.curveValues];
    final index = _curveIndex(state.curve.activeCurve);
    values[index] = state.curve.curveValue.clamp(-100, 100);
    return [values[0] & 0xFF, 0, values[1] & 0xFF, values[2] & 0xFF];
  }

  List<int> _buildFailsafePayload(List<ChannelState> channels) {
    return channels
        .take(11)
        .map((e) => e.failsafeActive ? (e.failsafeValue & 0xFF) : 0x7F)
        .toList();
  }

  List<int> _buildModelSwitchPayload(List<Model> models) {
    final index = models.indexWhere((model) => model.active);
    return [index < 0 ? 0 : index];
  }

  List<int> _buildSystemSettingPayload(RadioSettings settings) {
    final idle = settings.idleAlarm.clamp(10, 9999);
    return [
      settings.backlightTime.clamp(0, 99),
      idle & 0xFF,
      (idle >> 8) & 0xFF,
      settings.atmosphereLight ? 1 : 0,
    ];
  }

  List<int> _buildFourWheelSteerPayload(RcAppState state) {
    final snap = state.protocol.fourWheelSteer;
    return [
      snap.enabled ? 1 : 0,
      snap.channel.clamp(2, 10),
      snap.ratio.clamp(0, 100),
      snap.mode,
    ];
  }

  List<int> _buildTrackPayload(RcAppState state) {
    final snap = state.protocol.trackMixing;
    return [
      snap.enabled ? 1 : 0,
      snap.forwardRatio.clamp(0, 100),
      snap.backwardRatio.clamp(0, 100),
      snap.leftRatio.clamp(0, 100),
      snap.rightRatio.clamp(0, 100),
    ];
  }

  List<int> _buildDrivePayload(RcAppState state) {
    final snap = state.protocol.driveMixing;
    return [
      snap.enabled ? 1 : 0,
      snap.channel.clamp(2, 10),
      snap.frontRatio.clamp(0, 100),
      snap.rearRatio.clamp(0, 100),
      snap.mode.clamp(0, 2),
    ];
  }

  List<int> _buildBrakePayload(RcAppState state) {
    final snap = state.protocol.brakeMixing;
    return [
      snap.mixingNo,
      snap.enabled ? 1 : 0,
      snap.channel.clamp(2, 10),
      snap.exponentEnabled ? 1 : 0,
      snap.ratio.clamp(0, 100) & 0xFF,
      snap.curve & 0xFF,
    ];
  }

  List<int> _buildControlMappingPayload(ControlMappingState state) {
    final isCh5ThreeWay = _isCh5ThreeWayState(state);
    return [
      0,
      _controlChannelToIndex(state.channel),
      _controlStateCode(state.type),
      state.mode == '触发' ? 1 : 0,
      isCh5ThreeWay
          ? _ch5MixingModeCode(state.mixingFunction, state.mixingMode1)
          : _mixingModeCode(state.mixingMode1),
      isCh5ThreeWay
          ? _ch5MixingModeCode(state.mixingFunction, state.mixingMode2)
          : _mixingModeCode(state.mixingMode2),
      isCh5ThreeWay
          ? _ch5MixingModeCode(state.mixingFunction, state.mixingMode3)
          : _mixingModeCode(state.mixingMode3),
      isCh5ThreeWay
          ? _controlActionCode(state.action)
          : _controlActionCode(state.action),
      _controlFunctionCode(state),
    ];
  }

  String _clearModeIfDisabled(String currentMode, String targetMode) {
    return currentMode == targetMode ? '' : currentMode;
  }

  RcProtocolState _withOnlyMixingEnabled(
    RcProtocolState protocol,
    String mode,
  ) {
    return protocol.copyWith(
      fourWheelSteer: protocol.fourWheelSteer.copyWith(enabled: mode == '4WS'),
      trackMixing: protocol.trackMixing.copyWith(enabled: mode == 'TRACK'),
      driveMixing: protocol.driveMixing.copyWith(enabled: mode == 'DRIVE'),
      brakeMixing: protocol.brakeMixing.copyWith(enabled: mode == 'BRAKE'),
    );
  }

  (int, String) _trackFocus(TrackMixingSnapshot snap) {
    final candidates = <(int, String)>[
      (snap.forwardRatio, 'SAME'),
      (-snap.backwardRatio, 'SAME'),
      (-snap.leftRatio, 'OPPOSITE'),
      (snap.rightRatio, 'OPPOSITE'),
    ];
    candidates.sort((a, b) => b.$1.abs().compareTo(a.$1.abs()));
    return candidates.first;
  }

  int _curveIndex(String activeCurve) {
    if (activeCurve == 'Steering') return 0;
    if (activeCurve == 'Brake') return 2;
    return 1;
  }

  String _protocolChannelToUi(int idx) => 'CH${idx.clamp(2, 10) + 1}';

  List<int> _trimPayload(BluetoothFrame frame) {
    final len = frame.length.clamp(0, bluetoothDataLength);
    return frame.data.sublist(0, len);
  }

  int _int16(int lo, int hi) {
    final value = (lo & 0xFF) | ((hi & 0xFF) << 8);
    return value >= 0x8000 ? value - 0x10000 : value;
  }

  int _int8(int value) {
    final v = value & 0xFF;
    return v >= 0x80 ? v - 0x100 : v;
  }

  String _controlChannel(int value, {required String fallback}) {
    if (value >= 2 && value <= 10) return 'CH${value + 1}';
    return fallback;
  }

  int _controlChannelToIndex(String channel) {
    final v = int.tryParse(channel.replaceAll('CH', ''));
    return ((v ?? 11) - 1).clamp(2, 10);
  }

  String _controlStateText(int value) {
    return switch (value) {
      1 => '单击',
      2 => '双击',
      4 => '三击',
      8 => '长按',
      _ => '无',
    };
  }

  int _controlStateCode(String state) {
    return switch (state) {
      '单击' => 1,
      '双击' => 2,
      '三击' => 4,
      '长按' => 8,
      _ => 0,
    };
  }

  String _mixingModeText(int value) {
    return switch (value) {
      0 => '四轮转向',
      1 => '履带混控',
      2 => '驱动混控',
      _ => '刹车混控',
    };
  }

  int _mixingModeCode(String? value) {
    return switch (value) {
      '四轮转向' || '4WS' => 0,
      '履带混控' => 1,
      '驱动混控' => 2,
      '刹车混控' => 3,
      _ => 0,
    };
  }

  bool _isCh5ThreeWayState(ControlMappingState state) {
    return isCh5ThreeWaySwitch(state.channel, state.type) &&
        isCh5MixingAction(state.action);
  }

  bool _isCh5MixingFunctionCode(int value) {
    return value == 1 || value == 2;
  }

  bool _isCh5MixingPayload(int actionCode, int functionCode) {
    final legacy = _isCh5MixingFunctionCode(actionCode) && functionCode == 17;
    final current = actionCode == 1 && (functionCode == 11 || functionCode == 13);
    final transitional = actionCode == 2 && functionCode == 11;
    return legacy || current || transitional;
  }

  String _ch5MixingFunctionFromPayload(int actionCode, int functionCode) {
    if (functionCode == 11) return '四轮';
    if (functionCode == 13) return '混动';
    return _ch5MixingFunctionText(actionCode);
  }

  String _ch5MixingFunctionText(int value) {
    if (value == 1) return '混动';
    return '四轮';
  }

  String _ch5MixingModeText(String mixingFunction, int value) {
    if (mixingFunction == '混动') {
      if (value == 0) return '驱动混控后面';
      if (value == 1) return '驱动混控前面';
      return '驱动混控前后混控';
    }
    if (value == 0) return '四轮转向前面';
    if (value == 1) return '四轮转向前后反向';
    if (value == 2) return '四轮转向前后同向';
    return '四轮转向后面';
  }

  int _ch5MixingModeCode(String? mixingFunction, String? value) {
    if (mixingFunction == '混动') {
      if (value == '驱动混控后面' || value == '后驱' || value == '驱动混控后驱') {
        return 0;
      }
      if (value == '驱动混控前面' || value == '前驱' || value == '驱动混控前驱') {
        return 1;
      }
      return 2;
    }
    if (value == '四轮转向前面' || value == '前轮转向' || value == '四轮前轮转向') {
      return 0;
    }
    if (value == '四轮转向前后反向') return 1;
    if (value == '四轮转向前后同向') return 2;
    if (value == '四轮转向后面' || value == '后轮转向' || value == '四轮后轮转向') {
      return 3;
    }
    return 0;
  }

  String _ch5ActionText(int functionCode, String mixingFunction) {
    if (mixingFunction == '四轮') return '四轮混控';
    return '驱动混控';
  }

  String _controlActionText(int value, {int? functionCode}) {
    if (value == 1 && functionCode != null) {
      return controlMappingSwitchActionByCode(functionCode) ?? '混控功能切换';
    }
    if (value == 2) {
      return _trimActionFromCode(functionCode) ?? '方向微调';
    }
    if (value == 3) {
      return _ratioActionFromCode(functionCode) ?? '方向比率';
    }
    return switch (value) {
      0 => '通道输出',
      1 => '混控功能切换',
      _ => '无',
    };
  }

  int _controlActionCode(String action) {
    if (action == '通道输出' || _isChannelAction(action)) return 0;
    if (action == '四轮混控' || action == '驱动混控') return 1;
    if (_isSwitchAction(action)) return 1;
    if (_isTrimAction(action)) return 2;
    if (_isRatioAction(action)) return 3;
    return 0;
  }

  String? _functionChannel(int value) {
    if (value < 2 || value > 10) return null;
    return 'CH${value + 1}';
  }

  int _controlFunctionCode(ControlMappingState state) {
    if (state.targetChannel != null) {
      return _controlChannelToIndex(state.targetChannel!);
    }
    if (state.action == '四轮混控') return 11;
    if (state.action == '驱动混控') return 13;
    final switchCode = controlMappingSwitchActionCode(state.action);
    if (switchCode != null) return switchCode;
    final trimCode = _trimActionCode(state.action);
    if (trimCode != null) return trimCode;
    final ratioCode = _ratioActionCode(state.action);
    if (ratioCode != null) return ratioCode;
    return 0;
  }

  bool _isChannelAction(String action) {
    return action.startsWith('CH') &&
        int.tryParse(action.replaceAll('CH', '')) != null;
  }

  bool _isSwitchAction(String action) {
    return switch (action) {
      '混控功能切换' ||
      '四轮转向开关' ||
      '履带混控开关' ||
      '驱动混控开关' ||
      '刹车混控开关' ||
      '四轮转向模式切换' ||
      '履带混控切换' ||
      '驱动混控切换' ||
      '刹车混控切换' => true,
      _ => false,
    };
  }

  bool _isTrimAction(String action) {
    return _trimActionCode(action) != null;
  }

  bool _isRatioAction(String action) {
    return _ratioActionCode(action) != null;
  }

  int? _trimActionCode(String action) {
    return switch (action) {
      '方向普通微调' || '方向微调' => 15,
      '油门普通微调' || '油门微调' => 16,
      _ => null,
    };
  }

  String? _trimActionFromCode(int? code) {
    return switch (code) {
      15 => '方向微调',
      16 => '油门微调',
      _ => null,
    };
  }

  int? _ratioActionCode(String action) {
    return switch (action) {
      '方向比率' || '方向比率控制' => 17,
      '前进比率' || '油门前进比率' || '油门比率控制' => 18,
      '刹车比率' || '油门刹车比率' => 19,
      '四轮转向混控比率' || '四轮转向比率控制' => 20,
      '驱动混控前进比率' || '驱动混控比率' || '驱动混控比率控制' => 21,
      '驱动混控后退比率' => 22,
      '刹车混控1比率' || '刹车混控比率' || '刹车混控比率控制' => 23,
      '刹车混控2比率' => 24,
      _ => null,
    };
  }

  String? _ratioActionFromCode(int? code) {
    return switch (code) {
      17 => '方向比率',
      18 => '前进比率',
      19 => '刹车比率',
      20 => '四轮转向混控比率',
      21 => '驱动混控前进比率',
      22 => '驱动混控后退比率',
      23 => '刹车混控1比率',
      24 => '刹车混控2比率',
      _ => null,
    };
  }
}

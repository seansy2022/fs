import 'dart:async';

import '../logging/rc_logging.dart';
import 'bluetooth_frame.dart';
import 'bluetooth_frame_parser.dart';
import 'bluetooth_protocol_codec.dart';
import 'bluetooth_protocol_types.dart';

abstract class BluetoothProtocolChannel {
  Stream<List<int>> get bytes;
  Future<void> send(List<int> bytes);
}

enum _PendingRequestType { none, writeAck, readData }

class BluetoothRequestPolicy {
  const BluetoothRequestPolicy({
    this.defaultTimeout = const Duration(milliseconds: 500),
    this.controlMappingWriteTimeout = const Duration(milliseconds: 1200),
    this.readTimeout = const Duration(milliseconds: 1500),
    this.maxRetries = 1,
    this.readMaxRetries = 0,
    this.readTimeoutCooldown = const Duration(milliseconds: 500),
  }) : assert(maxRetries >= 0),
       assert(readMaxRetries >= 0);

  final Duration defaultTimeout;
  final Duration controlMappingWriteTimeout;
  final Duration readTimeout;
  final int maxRetries;
  final int readMaxRetries;
  final Duration readTimeoutCooldown;
}

class BluetoothProtocolClient {
  BluetoothProtocolClient({
    required BluetoothProtocolChannel channel,
    BluetoothRequestPolicy policy = const BluetoothRequestPolicy(),
  }) : _channel = channel,
       _policy = policy {
    _sub = _channel.bytes.listen(_onBytes);
  }

  static final Set<int> _mixingLogCommands = BluetoothCommand.values
      .where(
        (cmd) =>
            cmd != BluetoothCommand.channelDisplay &&
            cmd != BluetoothCommand.telemetryDisplay,
      )
      .map((cmd) => cmd.id)
      .toSet();

  final BluetoothProtocolChannel _channel;
  final BluetoothRequestPolicy _policy;
  final BluetoothFrameParser _parser = BluetoothFrameParser();
  final StreamController<ChannelSnapshot> _chCtrl =
      StreamController.broadcast();
  final StreamController<TelemetryPacket> _tmCtrl =
      StreamController.broadcast();
  final StreamController<PassthroughPacket> _psCtrl =
      StreamController.broadcast();
  final StreamController<BluetoothFrame> _frameCtrl =
      StreamController.broadcast();

  StreamSubscription<List<int>>? _sub;
  Completer<BluetoothFrame>? _pending;
  int? _pendingSeq;
  int? _pendingCommand;
  int? _pendingReadSignature;
  _PendingRequestType _pendingType = _PendingRequestType.none;
  bool _pendingAcceptAny = false;
  bool Function(BluetoothFrame frame)? _pendingMatcher;
  final Map<int, DateTime> _readCooldownUntil = <int, DateTime>{};
  int _seq = 0;

  Stream<ChannelSnapshot> get channelStream => _chCtrl.stream;
  Stream<TelemetryPacket> get telemetryStream => _tmCtrl.stream;
  Stream<PassthroughPacket> get passthroughStream => _psCtrl.stream;
  Stream<BluetoothFrame> get frameStream => _frameCtrl.stream;

  Future<AckResult> writeCommand(
    BluetoothCommand cmd,
    List<int> payload,
  ) async {
    if (_shouldLogCommandId(cmd.id)) {
      RcLogging.protocol(
        'write request cmd=${_cmdLabel(cmd.id)} payloadLen=${payload.length} payload=${RcLogging.hex(payload, maxBytes: 24)}',
        scope: 'BluetoothProtocolClient',
      );
    }
    final timeout = cmd == BluetoothCommand.controlMapping
        ? _policy.controlMappingWriteTimeout
        : _policy.defaultTimeout;
    final frame = await _request(
      () => buildWriteFrame(seq: _nextSeq(), command: cmd, payload: payload),
      acceptAnyResponse: false,
      responseMatcher: _isConfigAckFrame,
      timeout: timeout,
      requestType: _PendingRequestType.writeAck,
    );
    final ack = parseAck(frame) ?? const AckResult(code: 0x21);
    if (_shouldLogCommandId(cmd.id)) {
      RcLogging.protocol(
        'write ack cmd=${_cmdLabel(cmd.id)} code=0x${ack.code.toRadixString(16)}',
        scope: 'BluetoothProtocolClient',
      );
    }
    return ack;
  }

  Future<BluetoothFrame> readCommand(BluetoothCommand cmd) {
    if (_shouldLogCommandId(cmd.id)) {
      RcLogging.protocol(
        'read request cmd=${_cmdLabel(cmd.id)}',
        scope: 'BluetoothProtocolClient',
      );
    }
    return _requestRead(
      cmd: cmd,
      signature: 0,
      builder: () => buildReadFrame(seq: _nextSeq(), command: cmd),
    );
  }

  Future<BluetoothFrame> readCommandWithPayload(
    BluetoothCommand cmd,
    List<int> payload,
  ) {
    if (_shouldLogCommandId(cmd.id)) {
      RcLogging.protocol(
        'read request cmd=${_cmdLabel(cmd.id)} payloadLen=${payload.length} payload=${RcLogging.hex(payload, maxBytes: 24)}',
        scope: 'BluetoothProtocolClient',
      );
    }
    return _requestRead(
      cmd: cmd,
      signature: _payloadSignature(payload, lenZero: false),
      builder: () =>
          buildWriteFrame(seq: _nextSeq(), command: cmd, payload: payload),
    );
  }

  Future<BluetoothFrame> readCommandWithLenZeroPayload(
    BluetoothCommand cmd,
    List<int> payload,
  ) {
    if (_shouldLogCommandId(cmd.id)) {
      RcLogging.protocol(
        'read request cmd=${_cmdLabel(cmd.id)} payloadLen=0 payload=${RcLogging.hex(payload, maxBytes: 24)}',
        scope: 'BluetoothProtocolClient',
      );
    }
    return _requestRead(
      cmd: cmd,
      signature: _payloadSignature(payload, lenZero: true),
      builder: () => BluetoothFrame(
        seq: _nextSeq(),
        command: cmd.id,
        length: 0,
        data: payload,
      ),
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _chCtrl.close();
    await _tmCtrl.close();
    await _psCtrl.close();
    await _frameCtrl.close();
  }

  Future<BluetoothFrame> _request(
    BluetoothFrame Function() builder, {
    required bool acceptAnyResponse,
    bool Function(BluetoothFrame frame)? responseMatcher,
    Duration? timeout,
    int? maxRetries,
    _PendingRequestType requestType = _PendingRequestType.none,
    int? readSignature,
  }) async {
    final requestTimeout = timeout ?? _policy.defaultTimeout;
    final retry = maxRetries ?? _policy.maxRetries;
    final maxAttempt = retry + 1;
    for (var i = 0; i < maxAttempt; i++) {
      if (i > 0) {
        if (_shouldLogCommandId(_pendingCommand)) {
          RcLogging.protocol(
            'retry request attempt=${i + 1}/$maxAttempt',
            scope: 'BluetoothProtocolClient',
          );
        }
      }
      final got =
          await _tryRequest(
            builder,
            acceptAnyResponse: acceptAnyResponse,
            responseMatcher: responseMatcher,
            requestType: requestType,
            readSignature: readSignature,
          ).timeout(
            requestTimeout,
            onTimeout: () {
              _pending = null;
              _pendingSeq = null;
              _pendingCommand = null;
              _pendingReadSignature = null;
              _pendingType = _PendingRequestType.none;
              _pendingAcceptAny = false;
              _pendingMatcher = null;
              return null;
            },
          );
      if (got != null) return got;
      if (_pending != null) {
        if (_shouldLogCommandId(_pendingCommand)) {
          RcLogging.protocol(
            'clear stale pending cmd=${_cmdLabel(_pendingCommand ?? -1)}',
            scope: 'BluetoothProtocolClient',
          );
        }
        _pending = null;
        _pendingSeq = null;
        _pendingCommand = null;
        _pendingReadSignature = null;
        _pendingType = _PendingRequestType.none;
        _pendingAcceptAny = false;
        _pendingMatcher = null;
      }
    }
    if (_shouldLogCommandId(_pendingCommand)) {
      RcLogging.protocol('request timeout', scope: 'BluetoothProtocolClient');
    }
    throw TimeoutException('bluetooth request timeout');
  }

  Future<BluetoothFrame?> _tryRequest(
    BluetoothFrame Function() builder, {
    required bool acceptAnyResponse,
    bool Function(BluetoothFrame frame)? responseMatcher,
    required _PendingRequestType requestType,
    int? readSignature,
  }) async {
    if (_pending != null) {
      if (_shouldLogCommandId(_pendingCommand)) {
        RcLogging.protocol(
          'request dropped because another request is pending',
          scope: 'BluetoothProtocolClient',
        );
      }
      return null;
    }
    final frame = builder();
    if (_shouldLogCommandId(frame.command)) {
      RcLogging.protocol(
        'send frame seq=${frame.seq} cmd=${_cmdLabel(frame.command)} len=${frame.length} payload=${RcLogging.hex(frame.data.sublist(0, frame.length), maxBytes: 24)}',
        scope: 'BluetoothProtocolClient',
      );
    }
    final bytes = frame.toBytes();
    final wait = Completer<BluetoothFrame>();
    _pending = wait;
    _pendingSeq = frame.seq;
    _pendingCommand = frame.command;
    _pendingReadSignature = readSignature;
    _pendingType = requestType;
    _pendingAcceptAny = acceptAnyResponse;
    _pendingMatcher = responseMatcher;
    try {
      await _channel.send(bytes);
    } catch (_) {
      if (_shouldLogCommandId(frame.command)) {
        RcLogging.protocol(
          'send frame failed cmd=${_cmdLabel(frame.command)}',
          scope: 'BluetoothProtocolClient',
        );
      }
      _pending = null;
      _pendingSeq = null;
      _pendingCommand = null;
      _pendingReadSignature = null;
      _pendingType = _PendingRequestType.none;
      _pendingAcceptAny = false;
      _pendingMatcher = null;
      return null;
    }
    return wait.future.whenComplete(() {
      _pending = null;
      _pendingSeq = null;
      _pendingCommand = null;
      _pendingReadSignature = null;
      _pendingType = _PendingRequestType.none;
      _pendingAcceptAny = false;
      _pendingMatcher = null;
    });
  }

  void _onBytes(List<int> chunk) {
    for (final frame in _parser.append(chunk)) {
      if (_shouldLogCommandId(frame.command)) {
        RcLogging.protocol(
          'rx frame seq=${frame.seq} cmd=${_cmdLabel(frame.command)} len=${frame.length} payload=${RcLogging.hex(frame.data.sublist(0, frame.length), maxBytes: 24)}',
          scope: 'BluetoothProtocolClient',
        );
      }
      _frameCtrl.add(frame);
      _dispatchStream(frame);
      final matcher = _pendingMatcher;
      final matchPending =
          _pending != null &&
          frame.seq == _pendingSeq &&
          (_pendingAcceptAny || frame.command == _pendingCommand) &&
          (matcher == null || matcher(frame));
      if (matchPending) {
        if (_shouldLogCommandId(frame.command)) {
          RcLogging.protocol(
            'matched response cmd=${_cmdLabel(frame.command)}',
            scope: 'BluetoothProtocolClient',
          );
        }
        final pending = _pending;
        _pending = null;
        _pendingSeq = null;
        _pendingCommand = null;
        _pendingReadSignature = null;
        _pendingType = _PendingRequestType.none;
        _pendingAcceptAny = false;
        _pendingMatcher = null;
        if (pending != null && !pending.isCompleted) {
          pending.complete(frame);
        }
      }
    }
  }

  void _dispatchStream(BluetoothFrame frame) {
    final ch = parseChannelDisplay(frame);
    if (ch != null) _chCtrl.add(ch);
    final tm = parseTelemetryDisplay(frame);
    if (tm != null) _tmCtrl.add(tm);
    final ps = parsePassthrough(frame);
    if (ps != null) _psCtrl.add(ps);
  }

  int _nextSeq() {
    final value = _seq & 0xFF;
    _seq = (_seq + 1) & 0xFF;
    return value;
  }

  String _cmdLabel(int command) {
    final cmd = BluetoothCommand.fromId(command);
    if (cmd == null) return '0x${command.toRadixString(16)}';
    return '${cmd.name}(0x${command.toRadixString(16)})';
  }

  bool _shouldLogCommandId(int? command) {
    return command != null && _mixingLogCommands.contains(command);
  }

  bool _isReadDataFrame(BluetoothFrame frame) {
    return !_isConfigAckFrame(frame);
  }

  bool _isConfigAckFrame(BluetoothFrame frame) {
    if (frame.length != 1) return false;
    final code = frame.data.first & 0xFF;
    if (code < 0x20 || code > 0x2F) return false;
    return frame.command >= BluetoothCommand.channelReverse.id &&
        frame.command <= BluetoothCommand.systemSetting.id;
  }

  Future<BluetoothFrame> _requestRead({
    required BluetoothCommand cmd,
    required int signature,
    required BluetoothFrame Function() builder,
  }) async {
    final cooldownKey = _readCooldownKey(cmd.id, signature);
    final until = _readCooldownUntil[cooldownKey];
    if (until != null && DateTime.now().isBefore(until)) {
      if (_shouldLogCommandId(cmd.id)) {
        RcLogging.protocol(
          'skip read in cooldown cmd=${_cmdLabel(cmd.id)} sign=$signature',
          scope: 'BluetoothProtocolClient',
        );
      }
      throw TimeoutException('bluetooth request cooldown');
    }
    if (_pending != null &&
        _pendingType == _PendingRequestType.readData &&
        _pendingCommand == cmd.id &&
        _pendingReadSignature == signature) {
      if (_shouldLogCommandId(cmd.id)) {
        RcLogging.protocol(
          'dedupe read request cmd=${_cmdLabel(cmd.id)}',
          scope: 'BluetoothProtocolClient',
        );
      }
      return _pending!.future;
    }
    try {
      final frame = await _request(
        builder,
        acceptAnyResponse: false,
        responseMatcher: _isReadDataFrame,
        timeout: _policy.readTimeout,
        maxRetries: _policy.readMaxRetries,
        requestType: _PendingRequestType.readData,
        readSignature: signature,
      );
      _readCooldownUntil.remove(cooldownKey);
      return frame;
    } on TimeoutException {
      _readCooldownUntil[cooldownKey] = DateTime.now().add(
        _policy.readTimeoutCooldown,
      );
      rethrow;
    }
  }

  int _payloadSignature(List<int> payload, {required bool lenZero}) {
    var hash = lenZero ? 1 : 0;
    for (final b in payload) {
      hash = ((hash * 31) + (b & 0xFF)) & 0x7FFFFFFF;
    }
    return hash;
  }

  int _readCooldownKey(int cmd, int signature) {
    return ((cmd & 0xFF) << 24) | (signature & 0x00FFFFFF);
  }
}

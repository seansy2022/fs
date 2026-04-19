import 'dart:async';
import 'dart:math';

import '../protocol/bluetooth_frame.dart';
import '../protocol/bluetooth_protocol_types.dart';
import '../logging/rc_logging.dart';
import 'link_transport.dart';

class MockProtocolLinkTransport implements LinkTransport {
  MockProtocolLinkTransport({bool? enableLogs})
    : _enableLogs = enableLogs ?? _defaultLogEnabled;

  static const bool _defaultLogEnabled = bool.fromEnvironment(
    'RC_MOCK_LOG',
    defaultValue: RcLogging.linkEnabled,
  );

  final StreamController<List<BluetoothScanDevice>> _scanCtrl =
      StreamController.broadcast();
  final StreamController<List<int>> _incomingCtrl =
      StreamController.broadcast();
  final Map<int, List<int>> _payloadByCommand = _defaultPayloadByCommand();
  final bool _enableLogs;

  Timer? _telemetryTimer;
  bool _connected = false;
  int _tick = 0;
  int _seq = 0;

  @override
  LinkType get type => LinkType.ble;

  @override
  Stream<List<BluetoothScanDevice>> get scanResults => _scanCtrl.stream;

  @override
  Stream<List<int>> get incomingBytes => _incomingCtrl.stream;

  @override
  Future<void> startScan() async {
    _log('startScan');
    _scanCtrl.add([
      const BluetoothScanDevice(
        remoteId: 'MOCK_RC_001',
        name: 'Mock RC MG11',
        rssi: -42,
      ),
    ]);
  }

  @override
  Future<void> stopScan() async {
    _log('stopScan');
  }

  @override
  Future<void> connect(String remoteId) async {
    _log('connect remoteId=$remoteId');
    _connected = true;
    _startTelemetry();
  }

  @override
  Future<void> disconnect(String remoteId) async {
    _log('disconnect remoteId=$remoteId');
    _connected = false;
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
  }

  @override
  Future<void> send(List<int> bytes) async {
    final frame = BluetoothFrame.tryParse(bytes);
    if (frame == null) {
      _log('drop invalid frame: bytes=${bytes.length}');
      return;
    }
    final cmd = BluetoothCommand.fromId(frame.command);
    if (cmd == null) {
      _log('drop unknown command: 0x${frame.command.toRadixString(16)}');
      return;
    }
    if (_isConfigCommand(cmd)) {
      if (frame.length == 0) {
        final payload = _payloadByCommand[cmd.id] ?? const <int>[];
        _log(
          'recv READ cmd=${cmd.name}(0x${cmd.id.toRadixString(16)}) -> payloadLen=${payload.length}',
        );
        _emitFrame(
          BluetoothFrame(
            seq: frame.seq,
            command: cmd.id,
            length: payload.length,
            data: payload,
          ),
        );
      } else {
        _payloadByCommand[cmd.id] = frame.data.sublist(0, frame.length);
        _log(
          'recv WRITE cmd=${cmd.name}(0x${cmd.id.toRadixString(16)}) payloadLen=${frame.length}',
        );
        _emitAck(frame.seq, cmd.id);
      }
      return;
    }
    if (cmd == BluetoothCommand.passthrough) {
      _log(
        'recv PASSTHROUGH cmd=${cmd.name}(0x${cmd.id.toRadixString(16)}) payloadLen=${frame.length}',
      );
      _emitAck(frame.seq, cmd.id);
    }
  }

  Future<void> dispose() async {
    _log('dispose');
    _telemetryTimer?.cancel();
    await _scanCtrl.close();
    await _incomingCtrl.close();
  }

  void _startTelemetry() {
    _telemetryTimer?.cancel();
    _log('start telemetry ticker (300ms)');
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!_connected) return;
      _emitA1();
      _emitA2();
    });
  }

  void _emitA1() {
    final data = List<int>.filled(24, 0);
    for (var i = 0; i < 11; i++) {
      final wave = sin((_tick + i * 3) / 8.0);
      final value = (1500 + (wave * 500).round()).clamp(1000, 2000);
      final idx = i * 2;
      data[idx] = (value >> 8) & 0xFF;
      data[idx + 1] = value & 0xFF;
    }
    _tick++;
    _emitFrame(
      BluetoothFrame(
        seq: _nextSeq(),
        command: BluetoothCommand.channelDisplay.id,
        length: 22,
        data: data,
      ),
    );
    if (_tick % 10 == 0) {
      _log('push A1 channelDisplay len=22 tick=$_tick');
    }
  }

  void _emitA2() {
    final data = List<int>.filled(24, 0);
    _setSensor(data, 0, sensorType: 0x01, sensorId: 0x01, value: 50);
    _setSensor(data, 4, sensorType: 0x02, sensorId: 0x01, value: 74);
    _setSensor(data, 8, sensorType: 0x03, sensorId: 0x01, value: 42);
    _emitFrame(
      BluetoothFrame(
        seq: _nextSeq(),
        command: BluetoothCommand.telemetryDisplay.id,
        length: 12,
        data: data,
      ),
    );
    if (_tick % 10 == 0) {
      _log('push A2 telemetryDisplay len=12');
    }
  }

  void _setSensor(
    List<int> data,
    int offset, {
    required int sensorType,
    required int sensorId,
    required int value,
  }) {
    data[offset] = sensorType & 0xFF;
    data[offset + 1] = sensorId & 0xFF;
    data[offset + 2] = value & 0xFF;
    data[offset + 3] = (value >> 8) & 0xFF;
  }

  bool _isConfigCommand(BluetoothCommand cmd) {
    return cmd.id >= BluetoothCommand.channelReverse.id &&
        cmd.id <= BluetoothCommand.systemSetting.id;
  }

  void _emitAck(int seq, int command) {
    final cmd = BluetoothCommand.fromId(command);
    _log(
      'send ACK cmd=${cmd?.name ?? command}(0x${command.toRadixString(16)}) seq=$seq code=0x20',
    );
    _emitFrame(
      BluetoothFrame(seq: seq, command: command, length: 1, data: const [0x20]),
    );
  }

  void _emitFrame(BluetoothFrame frame) {
    _incomingCtrl.add(frame.toBytes());
  }

  int _nextSeq() {
    final value = _seq & 0xFF;
    _seq = (_seq + 1) & 0xFF;
    return value;
  }

  static Map<int, List<int>> _defaultPayloadByCommand() {
    return <int, List<int>>{
      0x11: List<int>.filled(11, 0),
      0x12: List<int>.generate(22, (_) => 100),
      0x13: List<int>.filled(22, 0),
      0x14: <int>[100, 0, 100, 100],
      0x15: <int>[0, 0, 0, 0],
      0x16: <int>[0, 2, 100, 0],
      0x17: List<int>.filled(11, 0x7F),
      0x18: <int>[0, 0, 0, 1],
      0x19: <int>[0],
      0x1A: <int>[0, 100, 100, 100, 100],
      0x1B: <int>[0, 2, 100, 100, 0],
      0x1C: <int>[0, 0, 2, 0, 100, 0],
      0x1D: <int>[0, 2, 1, 0, 0, 1, 2, 0, 2],
      0x1E: <int>[10, 0x58, 0x02, 1],
    };
  }

  void _log(String message) {
    if (!_enableLogs) return;
    RcLogging.link(message, scope: 'MockProtocolLinkTransport');
  }
}

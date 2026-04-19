import '../logging/rc_logging.dart';
import 'bluetooth_frame.dart';

class BluetoothFrameParser {
  final List<int> _buffer = <int>[];

  List<BluetoothFrame> append(List<int> bytes) {
    _buffer.addAll(bytes);
    final frames = <BluetoothFrame>[];
    while (_buffer.length >= bluetoothFrameLength) {
      final frame = _takeOne();
      if (frame == null) break;
      frames.add(frame);
    }
    return frames;
  }

  BluetoothFrame? _takeOne() {
    final start = _buffer.indexOf(bluetoothFrameHead);
    if (start < 0) {
      if (_buffer.isNotEmpty) {
        RcLogging.protocol(
          'drop unsynced buffer bytes=${_buffer.length}',
          scope: 'BluetoothFrameParser',
        );
      }
      _buffer.clear();
      return null;
    }
    if (start > 0) {
      RcLogging.protocol(
        'skip leading bytes=$start before frame head',
        scope: 'BluetoothFrameParser',
      );
      _buffer.removeRange(0, start);
    }
    if (_buffer.length < bluetoothFrameLength) return null;
    final chunk = _buffer.sublist(0, bluetoothFrameLength);
    final frame = BluetoothFrame.tryParse(chunk);
    if (frame == null) {
      RcLogging.protocol(
        'invalid frame dropped payload=${RcLogging.hex(chunk, maxBytes: 30)}',
        scope: 'BluetoothFrameParser',
      );
      _buffer.removeAt(0);
      return null;
    }
    _buffer.removeRange(0, bluetoothFrameLength);
    return frame;
  }
}

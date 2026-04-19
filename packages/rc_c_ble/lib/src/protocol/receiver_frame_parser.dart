import 'receiver_frame.dart';

class ReceiverFrameParser {
  final List<int> _buffer = <int>[];

  List<ReceiverFrame> addChunk(List<int> bytes) {
    if (bytes.isEmpty) {
      return const <ReceiverFrame>[];
    }
    _buffer.addAll(bytes);
    final frames = <ReceiverFrame>[];
    while (_buffer.isNotEmpty) {
      final headIndex = _buffer.indexOf(ReceiverFrame.head);
      if (headIndex == -1) {
        _buffer.clear();
        break;
      }
      if (headIndex > 0) {
        _buffer.removeRange(0, headIndex);
      }
      if (_buffer.length < 2) {
        break;
      }
      final frameLength = _buffer[1] & 0xFF;
      if (frameLength < ReceiverFrame.minimumLength) {
        _buffer.removeAt(0);
        continue;
      }
      if (_buffer.length < frameLength) {
        break;
      }
      final raw = _buffer.sublist(0, frameLength);
      _buffer.removeRange(0, frameLength);
      final frame = ReceiverFrame.tryParse(raw);
      if (frame != null) {
        frames.add(frame);
      }
    }
    return frames;
  }
}

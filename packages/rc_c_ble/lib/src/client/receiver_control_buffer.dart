import 'dart:collection';

import '../models/receiver_models.dart';

class ReceiverControlBuffer {
  ReceiverControlValues _baseValues = const ReceiverControlValues();
  final ListQueue<_AuxPulseFrame> _pendingAuxPulseFrames =
      ListQueue<_AuxPulseFrame>();

  void updateBase(ReceiverControlValues values) {
    _baseValues = values.sanitize();
  }

  void queueAuxPulse(int auxChannelIndex, int value) {
    if (auxChannelIndex < 0 || auxChannelIndex >= 8) {
      throw RangeError.range(auxChannelIndex, 0, 7, 'auxChannelIndex');
    }
    _pendingAuxPulseFrames.addLast(
      _AuxPulseFrame(auxChannelIndex, value.clamp(1000, 2000)),
    );
  }

  ReceiverControlValues consumeNextValues() {
    if (_pendingAuxPulseFrames.isEmpty) {
      return _baseValues;
    }
    final pulseFrame = _pendingAuxPulseFrames.removeFirst();
    final auxChannels = List<int>.from(_baseValues.auxChannels);
    auxChannels[pulseFrame.auxChannelIndex] = pulseFrame.value;
    return _baseValues.copyWith(auxChannels: auxChannels);
  }

  void clear() {
    _baseValues = const ReceiverControlValues();
    _pendingAuxPulseFrames.clear();
  }
}

class _AuxPulseFrame {
  const _AuxPulseFrame(this.auxChannelIndex, this.value);

  final int auxChannelIndex;
  final int value;
}

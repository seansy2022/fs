import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';
import '../../types.dart';

class Failsafe extends StatelessWidget {
  const Failsafe({
    super.key,
    required this.channels,
    required this.onUpdateChannel,
  });
  final List<ChannelState> channels;
  final void Function(String id, ChannelState next) onUpdateChannel;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: channels.map(_item).toList(growable: false),
    );
  }

  Widget _item(ChannelState ch) {
    final value = ch.failsafeValue;
    return Container(
      // height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFF001024),
        border: Border(
          bottom: BorderSide(color: Color(0xFF233854), width: 0.6),
        ),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
      child: Column(
        children: [
          _header(ch, value),
          const SizedBox(height: 2),
          _progress(ch, value),
        ],
      ),
    );
  }

  Widget _progress(ChannelState ch, int value) {
    return SizedBox(
      height: 37,
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: !ch.failsafeActive,
            child: ControlProgressBar(
              value: value.toDouble(),
              max: 120,
              scale: 0.6,
              showSignedLabels: false,
              highlightPlus: false,
              onMinus: () => _step(ch, -1),
              onPlus: () => _step(ch, 1),
            ),
          ),
          if (!ch.failsafeActive)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0x80001024)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(ChannelState ch, int value) {
    return SizedBox(
      width: double.infinity,
      // height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Row(
              children: [
                Text(ch.id, style: _titleStyle),
                const Spacer(),
                Text(_status(value), style: _statusStyle),
              ],
            ),
          ),
          RcMultiToggle<bool>(
            options: const [false, true],
            selected: ch.failsafeActive,
            onChanged: (v) => _setActive(ch, v),
            width: 100,
            keepSingleJoinBorder: true,
          ),
        ],
      ),
    );
  }

  void _setActive(ChannelState ch, bool active) {
    onUpdateChannel(ch.id, ch.copyWith(failsafeActive: active));
  }

  void _step(ChannelState ch, int delta) {
    final next = (ch.failsafeValue + delta).clamp(-120, 120);
    onUpdateChannel(ch.id, ch.copyWith(failsafeValue: next));
  }

  String _status(int value) {
    final abs = value.abs();
    if (value < 0) return 'L:$abs%';
    if (value > 0) return 'R:$abs%';
    return 'R:0%';
  }
}

const _titleStyle = AppTextStyles.failsafeTitle;
const _statusStyle = AppTextStyles.failsafeStatus;

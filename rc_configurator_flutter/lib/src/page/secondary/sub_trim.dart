import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../types.dart';

class SubTrim extends StatelessWidget {
  const SubTrim({
    super.key,
    required this.channels,
    required this.onUpdateChannel,
  });

  final List<ChannelState> channels;
  final void Function(String id, ChannelState next) onUpdateChannel;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: channels.length,
      separatorBuilder: (context, index) => const RcDivider(
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
      itemBuilder: (context, index) => _item(context, channels[index]),
    );
  }

  Widget _item(BuildContext context, ChannelState ch) {
    return NamedControlProgressWidget(
      title: ch.id,
      status: _status(ch),
      value: ch.offset.toDouble(),
      max: 120,
      showSignedLabels: false,
      highlightPlus: false,
      onMinus: () => _step(ch, -1),
      onPlus: () => _step(ch, 1),
      onRefresh: () => _confirmAndReset(context, ch),
    );
  }

  void _step(ChannelState ch, int delta) {
    final next = (ch.offset + delta).clamp(-120, 120);
    onUpdateChannel(ch.id, ch.copyWith(offset: next));
  }

  void _resetChannel(ChannelState ch) {
    onUpdateChannel(ch.id, ch.copyWith(offset: 0));
  }

  Future<void> _confirmAndReset(BuildContext context, ChannelState ch) async {
    final confirmed = await AlertModelWidget.show(
      context,
      title: '确认复位出场默认设置?',
      cancelText: '取消',
      confirmText: '确认',
    );
    if (confirmed != true) return;
    _resetChannel(ch);
  }

  String _status(ChannelState ch) {
    final value = ch.offset;
    final abs = value.abs();
    if (value < 0) return '${_negativeLabel(ch.id)}:$abs%';
    if (value > 0) return '${_positiveLabel(ch.id)}:$abs%';
    return '${_positiveLabel(ch.id)}:0%';
  }

  String _positiveLabel(String channelId) {
    if (channelId == 'CH1') return 'R';
    if (channelId == 'CH2') return 'F';
    if (channelId == 'CH5' || channelId == 'CH9') return 'R';
    return 'U';
  }

  String _negativeLabel(String channelId) {
    if (channelId == 'CH1') return 'L';
    if (channelId == 'CH2') return 'B';
    if (channelId == 'CH5' || channelId == 'CH9') return 'L';
    return 'D';
  }
}

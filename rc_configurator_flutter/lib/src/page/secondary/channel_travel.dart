import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../types.dart';

class ChannelTravel extends StatelessWidget {
  const ChannelTravel({
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
      children: channels
          .map((ch) => _item(context, ch))
          .toList(growable: false),
    );
  }

  Widget _item(BuildContext context, ChannelState ch) {
    final labels = _labelsFor(ch.id);
    return SidesControlProgressWidget(
      title: ch.id,
      leftStatus: '${labels.$1}:${ch.lLimit}%',
      rightStatus: '${labels.$2}:${ch.rLimit}%',
      leftValue: ch.lLimit,
      rightValue: ch.rLimit,
      max: 120,
      statusButtonType: RCIconButtonType.textButton,
      onAdjust: (leftSelected, delta) =>
          _updateSelected(ch, leftSelected, delta),
      onRefresh: () => _confirmAndReset(context, ch),
    );
  }

  (String, String) _labelsFor(String channelId) {
    if (channelId == 'CH1') return ('L', 'R');
    if (channelId == 'CH2') return ('B', 'F');
    return ('L', 'H');
  }

  void _updateSelected(ChannelState ch, bool leftSelected, int delta) {
    final leftDelta = leftSelected ? delta : 0;
    final rightDelta = leftSelected ? 0 : delta;
    final nextLeft = (ch.lLimit + leftDelta).clamp(0, 120);
    final nextRight = (ch.rLimit + rightDelta).clamp(0, 120);
    onUpdateChannel(ch.id, ch.copyWith(lLimit: nextLeft, rLimit: nextRight));
  }

  void _resetChannel(ChannelState ch) {
    onUpdateChannel(ch.id, ch.copyWith(lLimit: 100, rLimit: 100));
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
}

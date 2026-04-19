import 'package:flutter/material.dart';

import 'package:rc_ui/rc_ui.dart';
import '../../types.dart';

class ChannelReverse extends StatelessWidget {
  const ChannelReverse({
    super.key,
    required this.channels,
    required this.onUpdateChannel,
  });

  final List<ChannelState> channels;
  final void Function(String id, ChannelState next) onUpdateChannel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.gapL),
      children: [
        ...channels.map((ch) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.gapM),
            child: CellButtonWidget(
              title: ch.id,
              buttonText: ch.reverse ? '反向' : '正向',
              active: ch.reverse,
              onPressed: () =>
                  onUpdateChannel(ch.id, ch.copyWith(reverse: !ch.reverse)),
            ),
          );
        }),
      ],
    );
  }
}

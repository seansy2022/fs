import 'package:flutter/material.dart';

import 'package:rc_ui/rc_ui.dart';
import 'package:rc_configurator_flutter/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(AppDimens.gapL),
      children: [
        ...channels.map((ch) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.gapM),
            child: CellButtonWidget(
              title: ch.id,
              buttonText: ch.reverse ? l10n.rev : l10n.nor,
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

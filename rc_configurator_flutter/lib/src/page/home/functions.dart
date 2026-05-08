import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rc_ui/rc_ui.dart';
import 'package:rc_configurator_flutter/l10n/app_localizations.dart';
import '../../types.dart';

class Functions extends StatelessWidget {
  const Functions({super.key, required this.onNavigate});

  final ValueChanged<Screen> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final menu = <(Screen, String, String?)>[
      (Screen.reverse, l10n.channelReverse, AppAssets.menuChannelDirection),
      (Screen.channels, l10n.channelTravel, AppAssets.menuChannelTravel),
      (Screen.subTrim, l10n.subtrim, AppAssets.menuSubTrim),
      (Screen.dualRate, l10n.dualRate, AppAssets.doubleRate),
      (Screen.curve, l10n.curve, AppAssets.menuCurve),
      (Screen.controlMapping, l10n.controlAssign, AppAssets.menuControlMapping),
      (Screen.modelSelection, l10n.modelSelect, AppAssets.menuModelSelection),
      (Screen.failsafe, l10n.failsafe, AppAssets.menuFailsafe),
      (Screen.radioSettings, l10n.radioSettings, AppAssets.menuRadioSettings),
      (Screen.mixing, l10n.mixing, AppAssets.menuMixing),
    ];
    return ListView(
      padding: const EdgeInsets.all(AppDimens.gapL),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppDimens.gapM;
            final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: menu
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      child: WorkButton(
                        icon: _buildMenuIcon(item.$3),
                        title: item.$2,
                        onTap: () => onNavigate(item.$1),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuIcon(String? asset) {
    if (asset == null) {
      return const Icon(
        LucideIcons.gauge,
        color: AppColors.onPrimary,
        size: 48,
      );
    }
    return SvgPicture.asset(asset, width: 48, height: 48, fit: BoxFit.contain);
  }
}

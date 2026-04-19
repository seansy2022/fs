import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rc_ui/rc_ui.dart';
import '../../types.dart';

class Functions extends StatelessWidget {
  const Functions({super.key, required this.onNavigate});

  final ValueChanged<Screen> onNavigate;

  @override
  Widget build(BuildContext context) {
    final menu = <(Screen, String, String?)>[
      (Screen.reverse, '通道反向', AppAssets.menuChannelDirection),
      (Screen.channels, '通道行程', AppAssets.menuChannelTravel),
      (Screen.subTrim, '中立微调', AppAssets.menuSubTrim),
      (Screen.dualRate, '双比率', AppAssets.doubleRate),
      (Screen.curve, '曲线', AppAssets.menuCurve),
      (Screen.controlMapping, '控件分配', AppAssets.menuControlMapping),
      (Screen.modelSelection, '模型选择', AppAssets.menuModelSelection),
      (Screen.failsafe, '失控保护', AppAssets.menuFailsafe),
      (Screen.radioSettings, '遥控器设置', AppAssets.menuRadioSettings),
      (Screen.mixing, '混控', AppAssets.menuMixing),
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

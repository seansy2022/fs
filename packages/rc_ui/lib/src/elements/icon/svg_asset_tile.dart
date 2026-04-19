import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:rc_ui/src/core/theme/app_theme.dart';

class SvgAssetTile extends StatelessWidget {
  const SvgAssetTile({
    super.key,
    required this.asset,
    required this.selected,
    required this.onTap,
    this.radius = 12,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final bool selected;
  final VoidCallback onTap;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected ? AppColors.primaryBright : AppColors.line,
            width: selected ? AppDimens.borderStrong : AppDimens.borderThin,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: SvgPicture.asset(asset, fit: fit)),
            if (selected)
              Positioned.fill(
                child: Container(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

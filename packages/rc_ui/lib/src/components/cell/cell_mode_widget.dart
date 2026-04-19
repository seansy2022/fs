import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';
import 'cell.dart';

import 'package:rc_ui/src/core/app_assets.dart';

const _cellHighlightBase = Color(0x281B2D4D);

class CellModeWidget extends StatelessWidget {
  const CellModeWidget({
    super.key,
    required this.index,
    required this.name,
    required this.selected,
    required this.onTap,
    required this.onEdit,
  });

  final int index;
  final String name;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Cell(
      onTap: onTap,
      enableHighlight: true,
      highlightGradient: AppGradients.v24,
      highlightBaseColor: _cellHighlightBase,
      title: '', // 我们在自定义 Row 中处理标题
      padding: EdgeInsets.zero, // Cell 内部已有 padding 逻辑，这里设为 zero 避免叠加
      widget: Expanded(
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimens.compactCell(12),
                vertical: AppDimens.compactCell(16),
              ),
              child: Row(
                children: [
                  _SelectIndicator(selected: selected),
                  SizedBox(width: AppDimens.compactCell(12)),
                  _title(),
                ],
              ),
            ),
            const Spacer(),
            _editButton(),
          ],
        ),
      ),
    );
  }

  Widget _title() {
    return Text(
      '$index：$name',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.text.withValues(alpha: selected ? 1 : 0.78),
        fontSize: AppFonts.s14,
        height: 1,
      ),
    );
  }

  Widget _editButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onEdit,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppDimens.compactCell(12)),
        height: AppDimens.compactCell(24),
        child: SvgPicture.asset(
          AppAssets.edit,
          fit: BoxFit.contain,
          // width: AppDimens.compactIcon(24),
          // height: AppDimens.compactIcon(24),
        ),
      ),
    );
  }
}

class _SelectIndicator extends StatelessWidget {
  const _SelectIndicator({required this.selected});

  final bool selected;
  static const _selectedAsset = AppAssets.cellModeSelected;
  static const _unselectedAsset = AppAssets.cellModeUnselected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimens.compactCell(24),
      height: AppDimens.compactCell(24),
      child: SvgPicture.asset(
        selected ? _selectedAsset : _unselectedAsset,
        fit: BoxFit.contain,
      ),
    );
  }
}

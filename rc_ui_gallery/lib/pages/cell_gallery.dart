import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

class CellGallery extends StatelessWidget {
  const CellGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('单元格 (Cells)')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.gapL),
        children: [
          const Text('CellButtonWidget (按钮行)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          CellButtonWidget(
            title: '进入子设置',
            buttonText: '配置',
            onPressed: () {},
          ),
          const SizedBox(height: 32),
          const Text('CellSwitchWidget (开关行)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          CellSwitchWidget(
            title: '飞行模式',
            value: true,
            onChanged: (v) {},
          ),
          const SizedBox(height: AppDimens.gapM),
          CellSwitchWidget(
            title: '定高模式',
            value: false,
            onChanged: (v) {},
          ),
          const SizedBox(height: 32),
          const Text('CellRateWidget (加减调整型)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          CellRateWidget(
            title: '精细调节',
            value: 50,
            onMinus: () {},
            onPlus: () {},
          ),
          const SizedBox(height: 32),
          const Text('CellModeWidget (列表选择模式)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          CellModeWidget(
            index: 1,
            name: '标准模式',
            selected: true,
            onTap: () {},
            onEdit: () {},
          ),
          const SizedBox(height: 8),
          CellModeWidget(
            index: 2,
            name: '运动模式',
            selected: false,
            onTap: () {},
            onEdit: () {},
          ),
          const SizedBox(height: 32),
          const Text('CellIconTextWidget (图标和文本后缀)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          CellIconTextWidget(
            title: '系统版本',
            valueText: 'v1.2.0',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          const Text('CellIconWidget (图标后缀)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          CellIconWidget(
            title: '更多设置',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          const Text('ButtonCell (开关样式二)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          ButtonCell(
            label: '辅助功能',
            value: true,
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }
}

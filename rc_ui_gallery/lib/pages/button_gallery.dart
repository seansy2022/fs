import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

class ButtonGallery extends StatelessWidget {
  const ButtonGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('按钮 (Buttons)')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.gapL),
        children: [
          const Text('Primary Button (主干按钮)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          PrimaryButton(
            text: '主操作 (正常)',
            onTap: () {},
          ),
          const SizedBox(height: AppDimens.gapM),
          const PrimaryButton(
            text: '主操作 (禁用)',
            onTap: null,
          ),
          const Text('RCIconButton (通用图标/文字按钮)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          Wrap(
            spacing: AppDimens.gapM,
            runSpacing: AppDimens.gapM,
            children: [
              RCIconButton(
                plus: true,
                onTap: () {},
              ),
              RCIconButton(
                plus: false,
                onTap: () {},
              ),
              RCIconButton(
                icon: Icons.settings,
                text: '设置',
                onTap: () {},
              ),
              RCIconButton(
                icon: Icons.share,
                text: '水平正常样式',
                isSquare: false,
                onTap: () {},
              ),
              const RCIconButton(
                icon: Icons.lock,
                text: '激活态',
                active: true,
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

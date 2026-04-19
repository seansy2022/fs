import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

class ThemeGallery extends StatelessWidget {
  const ThemeGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('配色与字体 (Theme)')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.gapL),
        children: [
          const Text('色彩色板 (AppColors)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          Wrap(
            spacing: AppDimens.gapM,
            runSpacing: AppDimens.gapM,
            children: [
              _colorBox('Bg', AppColors.bg),
              _colorBox('Surface', AppColors.surface),
              _colorBox('Primary', AppColors.primary),
              _colorBox('Tertiary', AppColors.tertiary),
              _colorBox('Text', AppColors.text),
              _colorBox('TextDim', AppColors.textDim),
            ],
          ),
          const SizedBox(height: 32),
          const Text('排版字号 (AppFonts & AppTextStyles)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          Container(
            padding: const EdgeInsets.all(AppDimens.gapL),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('字号 s20 (AppFonts.s20)', style: TextStyle(fontSize: AppFonts.s20)),
                Text('字号 s18 (AppFonts.s18)', style: TextStyle(fontSize: AppFonts.s18)),
                Text('字号 s16 (AppFonts.s16)', style: TextStyle(fontSize: AppFonts.s16)),
                Text('字号 s14 (AppFonts.s14)', style: TextStyle(fontSize: AppFonts.s14)),
                Text('字号 s12 (AppFonts.s12)', style: TextStyle(fontSize: AppFonts.s12)),
                const Divider(color: AppColors.line, height: 32),
                const Text('AppTextStyles.caption', style: AppTextStyles.caption),
                const Text('AppTextStyles.captionStrong', style: AppTextStyles.captionStrong),
                const Text('AppTextStyles.sectionLabel', style: AppTextStyles.sectionLabel),
                const Text('AppTextStyles.matrixLabel', style: AppTextStyles.matrixLabel),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _colorBox(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
            border: Border.all(color: AppColors.outline),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 10, color: AppColors.textDim)),
      ],
    );
  }
}

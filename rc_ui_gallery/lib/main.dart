import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

import 'pages/theme_gallery.dart';
import 'pages/button_gallery.dart';
import 'pages/cell_gallery.dart';
import 'pages/progress_gallery.dart';
import 'pages/slider_gallery.dart';
import 'pages/value_control_gallery.dart';

void main() {
  runApp(const GalleryApp());
}

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RC UI Gallery',
      theme: appTheme(),
      home: const GalleryHome(),
    );
  }
}

class GalleryHome extends StatelessWidget {
  const GalleryHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RC UI 画廊 (Sandbox)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.gapL),
        children: [
          _buildItem(context, '配色与字体 (Theme)', const ThemeGallery()),
          const SizedBox(height: AppDimens.gapM),
          _buildItem(context, '按钮 (Buttons)', const ButtonGallery()),
          const SizedBox(height: AppDimens.gapM),
          _buildItem(context, '单元格 (Cells)', const CellGallery()),
          const SizedBox(height: AppDimens.gapM),
          _buildItem(context, '进度与控制条 (Progress)', const ProgressGallery()),
          const SizedBox(height: AppDimens.gapM),
          _buildItem(context, '滑块与曲线 (Slider)', const SliderGallery()),
          const SizedBox(height: AppDimens.gapM),
          _buildItem(context, '数值控制组 (Value Control)', const ValueControlGallery()),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, Widget page) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimens.gapL),
        decoration: AppDecorations.panel,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.captionStrong),
            const Icon(Icons.chevron_right, size: AppDimens.chevron, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

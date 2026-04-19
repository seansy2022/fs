import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

class ProgressGallery extends StatelessWidget {
  const ProgressGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('进度与控制条 (Progress)')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.gapL),
        children: [
          const Text('ControlProgressBar (基础控制条)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          ControlProgressBar(
            value: 50,
            max: 100,
            onMinus: () {},
            onPlus: () {},
          ),
          const SizedBox(height: 32),
          const Text('NamedControlProgressWidget (带标题控制条)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          NamedControlProgressWidget(
            title: '微调',
            status: '50',
            value: 50,
            max: 100,
            onMinus: () {},
            onPlus: () {},
          ),
          const SizedBox(height: 32),
          const Text('RcMultiToggle (安全开关)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          RcMultiToggle<bool>(
            options: const [false, true],
            selected: true,
            onChanged: (v) {},
            width: 100,
          ),
          const SizedBox(height: AppDimens.gapM),
          RcMultiToggle<bool>(
            options: const [false, true],
            selected: false,
            onChanged: (v) {},
            width: 100,
          ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

class ValueControlGallery extends StatelessWidget {
  const ValueControlGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数值控制组 (Value Control)')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.gapL),
        children: [
          const Text('ControlValueWidget (横向)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          ControlValueWidget(
            label: 'CH1',
            valueText: '0',
            style: ControlValueStyle.horizontal,
            onMinus: () {},
            onPlus: () {},
          ),
          const SizedBox(height: 32),
          const Text('ControlValueWidget (竖向)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          Center(
            child: ControlValueWidget(
              label: 'CH2',
              valueText: '50',
              style: ControlValueStyle.vertical,
              onMinus: () {},
              onPlus: () {},
            ),
          ),
        ],
      ),
    );
  }
}

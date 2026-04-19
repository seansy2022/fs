import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

class SliderGallery extends StatefulWidget {
  const SliderGallery({super.key});

  @override
  State<SliderGallery> createState() => _SliderGalleryState();
}

class _SliderGalleryState extends State<SliderGallery> {
  int _sliderValue = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('滑块与曲线 (Slider)')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.gapL),
        children: [
          const Text('CurveSlider (曲线调整滑块)', style: AppTextStyles.captionStrong),
          const SizedBox(height: AppDimens.gapM),
          CurveSlider(
            title: 'EXPO',
            value: _sliderValue,
            onChange: (v) {
              setState(() {
                _sliderValue = v;
              });
            },
          ),
        ],
      ),
    );
  }
}

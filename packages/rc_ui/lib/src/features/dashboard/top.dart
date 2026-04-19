import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rc_ui/src/core/app_assets.dart';

import 'top_data.dart';
import 'top_painter.dart';

class ControlMappingTop extends StatefulWidget {
  const ControlMappingTop({
    super.key,
    required this.selectedChannel,
    required this.onTap,
  });

  final String selectedChannel;
  final ValueChanged<String> onTap;

  @override
  State<ControlMappingTop> createState() => _ControlMappingTopState();
}

class _ControlMappingTopState extends State<ControlMappingTop> {
  static const _asset = AppAssets.topBackground;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load(_asset);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _image = frame.image);
  }

  void _handleTap(TapDownDetails d, Size size) {
    final channel = topHitChannel(d.localPosition, size);
    if (channel != null) widget.onTap(channel);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: topDesignSize.width / topDesignSize.height,
      child: LayoutBuilder(
        builder: (context, c) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _handleTap(d, c.biggest),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: TopPainter(
                  selectedChannel: widget.selectedChannel,
                  image: _image,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );
  }
}

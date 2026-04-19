import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:rc_ui/src/layout/shell/top_drawer.dart';

class TopPainter extends CustomPainter {
  const TopPainter({required this.selectedChannel, required this.image});

  final String selectedChannel;
  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    TopDrawer.draw(canvas, size, image, selectedChannel);
  }

  @override
  bool shouldRepaint(covariant TopPainter oldDelegate) {
    return selectedChannel != oldDelegate.selectedChannel ||
        image != oldDelegate.image;
  }
}

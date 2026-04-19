import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:rc_ui/src/features/dashboard/top_data.dart';
import 'top_draw_base.dart';
import 'top_draw_nodes.dart';

class TopDrawer {
  static void draw(
    Canvas c,
    Size size,
    ui.Image? image,
    String selectedChannel,
  ) {
    final sx = size.width / topDesignSize.width;
    final sy = size.height / topDesignSize.height;
    TopDrawBase.draw(c, sx, sy, image);
    TopDrawNodes.draw(c, sx, sy, selectedChannel);
  }
}

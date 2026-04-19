import 'package:flutter/material.dart';

const topDesignSize = Size(686, 743);
const topImageRect = Rect.fromLTWH(139, 103, 408, 640);
const topImageRadius = Radius.circular(16);
const topPathPoints = <List<Offset>>[
  [Offset(567, 171.5), Offset(410.5, 171.5), Offset(410.5, 162)],
  [Offset(567, 310.5), Offset(381, 310.5)],
  [Offset(119, 240.5), Offset(357.5, 240.5), Offset(357.5, 151)],
  [Offset(119, 448.5), Offset(333.5, 448.5), Offset(333.5, 380)],
  [Offset(119, 31.5), Offset(410.5, 31.5), Offset(410.5, 132)],
  [Offset(119, 347.5), Offset(305, 347.5)],
  [Offset(567, 31.5), Offset(445.5, 31.5), Offset(445.5, 133)],
  [Offset(357, 448.5), Offset(567, 448.5)],
  [Offset(119, 124.5), Offset(389, 124.5)],
];
const topDots = <Offset>[
  Offset(445.5, 139.5),
  Offset(395.5, 124.5),
  Offset(410.5, 138.5),
  Offset(410.5, 155.5),
  Offset(357.5, 144.5),
  Offset(374.5, 310.5),
  Offset(311.5, 347.5),
  Offset(333.5, 373.5),
  Offset(350.5, 448.5),
];

class TopChannelNode {
  const TopChannelNode(this.id, this.rect, this.textOffset);

  final String id;
  final Rect rect;
  final Offset textOffset;
}

const topChannelNodes = <TopChannelNode>[
  TopChannelNode('CH11', Rect.fromLTWH(0, 0, 120, 64), Offset(20, 13)),
  TopChannelNode('CH7', Rect.fromLTWH(0, 104, 120, 64), Offset(29, 117)),
  TopChannelNode('CH9', Rect.fromLTWH(0, 208, 120, 64), Offset(29, 221)),
  TopChannelNode('CH6', Rect.fromLTWH(0, 312, 120, 64), Offset(29, 325)),
  TopChannelNode('CH4', Rect.fromLTWH(0, 416, 120, 64), Offset(29, 429)),
  TopChannelNode('CH8', Rect.fromLTWH(566, 0, 120, 64), Offset(595, 13)),
  TopChannelNode('CH10', Rect.fromLTWH(566, 139, 120, 64), Offset(586, 152)),
  TopChannelNode('CH5', Rect.fromLTWH(566, 278, 120, 64), Offset(595, 291)),
  TopChannelNode('CH3', Rect.fromLTWH(566, 416, 120, 64), Offset(595, 429)),
];

String? topHitChannel(Offset local, Size size) {
  if (size.width <= 0 || size.height <= 0) return null;
  final p = Offset(
    local.dx * topDesignSize.width / size.width,
    local.dy * topDesignSize.height / size.height,
  );
  for (final node in topChannelNodes) {
    if (node.rect.contains(p)) return node.id;
  }
  return null;
}

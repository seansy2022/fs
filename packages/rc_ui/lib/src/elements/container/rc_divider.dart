import 'package:flutter/material.dart';

class RcDivider extends StatelessWidget {
  const RcDivider({
    super.key,
    this.padding = EdgeInsets.zero,
    this.color = const Color(0xFF233854),
    this.height = 0.6,
  });

  /// 分割线的内边距，默认无边距（最宽）
  final EdgeInsetsGeometry padding;

  /// 分割线颜色，默认采用通道行程风格颜色
  final Color color;

  /// 分割线高度（厚度），默认 0.6
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Divider(
        height: height,
        thickness: height,
        color: color,
      ),
    );
  }
}

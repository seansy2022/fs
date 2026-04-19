import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget buildHalfSizeSvgAsset(
  String assetPath, {
  BoxFit fit = BoxFit.contain,
  double widthFactor = 0.3,
}) {
  return FractionallySizedBox(
    widthFactor: widthFactor,
    child: SvgPicture.asset(assetPath, fit: fit),
  );
}

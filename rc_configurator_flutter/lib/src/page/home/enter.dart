import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:rc_ui/rc_ui.dart';

class EnterPage extends StatelessWidget {
  const EnterPage({super.key});

  static const _topAsset = AppAssets.startupTop;
  static const _bottomAsset = AppAssets.startupBottom;
  static const _bottomIconAsset = AppAssets.startupBottomIcon;
  static const _bottomIconShift = -10.0;
  static const _bottomScale = 0.9;

  Widget _buildBottomAsset() {
    return FractionallySizedBox(
      widthFactor: 0.5,
      child: AspectRatio(
        aspectRatio: 244 / 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset(_bottomAsset, fit: BoxFit.contain),
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(_bottomIconShift, 0),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Image(image: AssetImage(_bottomIconAsset)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A12),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned(
                  top: constraints.maxHeight * 0.3,
                  left: 0,
                  right: 0,
                  child: buildHalfSizeSvgAsset(_topAsset, widthFactor: 0.4),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: constraints.maxHeight * 0.08,
                  child: Align(
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: _bottomScale,
                      child: _buildBottomAsset(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

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

  Widget _buildBottomAsset(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    // final isZh = true;
    if (isZh) {
      return Transform.scale(
        scale: _bottomScale,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          child: AspectRatio(
            aspectRatio: 244 / 56,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgPicture.asset(_bottomAsset, fit: BoxFit.contain),
                _buildIconOverlay(),
              ],
            ),
          ),
        ),
      );
    }
    return _buildEnglishBottom();
  }

  Widget _buildEnglishBottom() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: const Offset(_bottomIconShift, 0),
          child: const SizedBox(
            width: 28,
            height: 28,
            child: Image(image: AssetImage(_bottomIconAsset)),
          ),
        ),
        const SizedBox(width: 4),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEDF5FF), Color(0xFF92C3FF)],
            stops: [0.5139, 1.0],
          ).createShader(bounds),
          child: const Text(
            'MG11 Assistant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconOverlay() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: const Offset(_bottomIconShift, 0),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Image(image: AssetImage(_bottomIconAsset)),
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
                    child: _buildBottomAsset(context),
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

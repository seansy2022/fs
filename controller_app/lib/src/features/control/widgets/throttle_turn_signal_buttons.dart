import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _rightTurnSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="72" height="72" viewBox="0 0 72 72" fill="none"><circle cx="36" cy="36" r="36" fill="#001024" fill-opacity="0.4"></circle><path fill-rule="evenodd" fill="url(#linear_border_2_630_0)" d="M36 72C55.8823 72 72 55.8823 72 36C72 16.1177 55.8823 0 36 0C16.1177 0 0 16.1177 0 36C0 55.8823 16.1177 72 36 72ZM36 2C54.7777 2 70 17.2223 70 36C70 54.7777 54.7777 70 36 70C17.2223 70 2 54.7777 2 36C2 17.2223 17.2223 2 36 2Z"></path><path d="M33.1894 27.848L20.2714 27.848L20.2714 22.859C20.2714 22.5065 20.0884 22.2082 19.7746 22.0726C19.4608 21.9371 19.1208 21.9913 18.8855 22.2353L5.2615 35.3859C5.1046 35.5486 5 35.7655 5 36.0095C5 36.2536 5.1046 36.4705 5.2615 36.6332L18.8855 49.7838C19.0424 49.9194 19.2516 50.0007 19.4346 50.0007C19.5392 50.0007 19.67 50.0007 19.7746 49.9194C20.0622 49.7838 20.2714 49.4855 20.2714 49.133L20.2714 44.1439L33.1894 44.1439C33.6339 44.1439 34 43.7643 34 43.3034L34 28.6886C34 28.2277 33.6339 27.848 33.1894 27.848Z" fill="#7DA2CE"></path><path d="M66.7385 35.3859L53.1145 22.2353C52.8792 21.9913 52.5392 21.9371 52.2254 22.0726C51.9378 22.2082 51.7286 22.5065 51.7286 22.859L51.7286 27.848L38.8106 27.848C38.3661 27.848 38 28.2277 38 28.6886L38 43.3034C38 43.7643 38.3661 44.1439 38.8106 44.1439L51.7286 44.1439L51.7286 49.133C51.7286 49.4855 51.9116 49.7838 52.2254 49.9194C52.33 49.9736 52.4346 50.0007 52.5654 50.0007C52.7746 50.0007 52.9576 49.9194 53.1145 49.7838L66.7385 36.6332C66.8954 36.4705 67 36.2536 67 36.0095C67 35.7655 66.8954 35.5486 66.7385 35.3859Z" fill="#00C6FF"></path><defs><linearGradient id="linear_border_2_630_0" x1="36" y1="72" x2="36" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#7EA2CF" stop-opacity="0.4"/><stop offset="0.2807" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="0.5394" stop-color="#7DA2CE"/><stop offset="0.7815" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="1" stop-color="#7DA2CE" stop-opacity="0.4"/></linearGradient></defs></svg>
''';

const _leftTurnSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="72" height="72" viewBox="0 0 72 72" fill="none"><circle cx="36" cy="36" r="36" fill="#001024" fill-opacity="0.4"></circle><path fill-rule="evenodd" fill="url(#linear_border_2_630_0)" d="M36 72C55.8823 72 72 55.8823 72 36C72 16.1177 55.8823 0 36 0C16.1177 0 0 16.1177 0 36C0 55.8823 16.1177 72 36 72ZM36 2C54.7777 2 70 17.2223 70 36C70 54.7777 54.7777 70 36 70C17.2223 70 2 54.7777 2 36C2 17.2223 17.2223 2 36 2Z"></path><path d="M33.1894 27.848L20.2714 27.848L20.2714 22.859C20.2714 22.5065 20.0884 22.2082 19.7746 22.0726C19.4608 21.9371 19.1208 21.9913 18.8855 22.2353L5.2615 35.3859C5.1046 35.5486 5 35.7655 5 36.0095C5 36.2536 5.1046 36.4705 5.2615 36.6332L18.8855 49.7838C19.0424 49.9194 19.2516 50.0007 19.4346 50.0007C19.5392 50.0007 19.67 50.0007 19.7746 49.9194C20.0622 49.7838 20.2714 49.4855 20.2714 49.133L20.2714 44.1439L33.1894 44.1439C33.6339 44.1439 34 43.7643 34 43.3034L34 28.6886C34 28.2277 33.6339 27.848 33.1894 27.848Z" fill="#00C6FF"></path><path d="M66.7385 35.3859L53.1145 22.2353C52.8792 21.9913 52.5392 21.9371 52.2254 22.0726C51.9378 22.2082 51.7286 22.5065 51.7286 22.859L51.7286 27.848L38.8106 27.848C38.3661 27.848 38 28.2277 38 28.6886L38 43.3034C38 43.7643 38.3661 44.1439 38.8106 44.1439L51.7286 44.1439L51.7286 49.133C51.7286 49.4855 51.9116 49.7838 52.2254 49.9194C52.33 49.9736 52.4346 50.0007 52.5654 50.0007C52.7746 50.0007 52.9576 49.9194 53.1145 49.7838L66.7385 36.6332C66.8954 36.4705 67 36.2536 67 36.0095C67 35.7655 66.8954 35.5486 66.7385 35.3859Z" fill="#7DA2CE"></path><defs><linearGradient id="linear_border_2_630_0" x1="36" y1="72" x2="36" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#7EA2CF" stop-opacity="0.4"/><stop offset="0.2807" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="0.5394" stop-color="#7DA2CE"/><stop offset="0.7815" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="1" stop-color="#7DA2CE" stop-opacity="0.4"/></linearGradient></defs></svg>
''';

class ThrottleTurnSignalButtons extends StatelessWidget {
  const ThrottleTurnSignalButtons({
    super.key,
    required this.leftOn,
    required this.rightOn,
    required this.onLeftTap,
    required this.onRightTap,
    this.size = 36,
    this.gap = 8,
  });

  final bool leftOn;
  final bool rightOn;
  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;
  final double size;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TurnButton(
          svg: _leftTurnSvg,
          active: leftOn,
          onTap: onLeftTap,
          size: size,
        ),
        SizedBox(width: gap),
        _TurnButton(
          svg: _rightTurnSvg,
          active: rightOn,
          onTap: onRightTap,
          size: size,
        ),
      ],
    );
  }
}

class _TurnButton extends StatelessWidget {
  const _TurnButton({
    required this.svg,
    required this.active,
    required this.onTap,
    required this.size,
  });

  final String svg;
  final bool active;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Opacity(
        opacity: active ? 1 : 0.72,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SvgPicture.string(svg, width: size, height: size),
          ),
        ),
      ),
    );
  }
}

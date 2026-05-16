import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _indicatorDialSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96" fill="none"><circle cx="48" cy="48" r="48" fill="#001024" fill-opacity="0.4"></circle><path fill-rule="evenodd" fill="url(#linear_border_2_521_0)" d="M48 96C74.5097 96 96 74.5097 96 48C96 21.4903 74.5097 0 48 0C21.4903 0 0 21.4903 0 48C0 74.5097 21.4903 96 48 96ZM48 2C73.4051 2 94 22.5949 94 48C94 73.4051 73.4051 94 48 94C22.5949 94 2 73.4051 2 48C2 22.5949 22.5949 2 48 2Z"></path><path fill-rule="evenodd" d="M46.9945 16C38.804 16.2514 31.3898 19.5764 25.8646 24.864L30.1166 29.116C34.5531 24.9131 40.4614 22.2498 46.9945 22.0027L46.9945 16ZM48.9955 22.0027L48.9955 16C57.186 16.2514 64.6102 19.5764 70.1354 24.864L65.8834 29.116C61.4469 24.9131 55.5286 22.2498 48.9955 22.0027ZM67.284 30.5466C71.2558 34.9319 73.7581 40.67 73.9972 46.9941L80 46.9941C79.755 39.013 76.5902 31.7721 71.536 26.2947L67.284 30.5466ZM80 48.995L73.9972 48.995C73.8475 52.9538 72.8129 56.6862 71.0858 60L77.6889 60C79.0714 56.5848 79.8808 52.8769 80 48.995ZM18.3111 60L24.9142 60C23.187 56.6862 22.1525 52.9538 22.0028 48.995L16 48.995C16.1192 52.8769 16.9287 56.5848 18.3111 60ZM16 46.9941L22.0028 46.9941C22.242 40.67 24.7441 34.9319 28.716 30.5466L24.464 26.2947C19.4097 31.7721 16.245 39.013 16 46.9941Z" fill="#EDF5FF"></path><g><text transform="translate(28, 58)"><tspan x="0" y="21.2" font-size="20" fill="#EDF5FF" font-family="PingFang SC">方向</tspan></text></g><defs><linearGradient id="linear_border_2_521_0" x1="48" y1="96" x2="48" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#7EA2CF" stop-opacity="0.4"/><stop offset="0.2807" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="0.5394" stop-color="#7DA2CE"/><stop offset="0.7815" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="1" stop-color="#7DA2CE" stop-opacity="0.4"/></linearGradient></defs></svg>
''';

const _throttleDialSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96" fill="none"><circle cx="48" cy="48" r="48" fill="#001024" fill-opacity="0.4"></circle><path fill-rule="evenodd" fill="url(#linear_border_2_530_0)" d="M48 96C74.5097 96 96 74.5097 96 48C96 21.4903 74.5097 0 48 0C21.4903 0 0 21.4903 0 48C0 74.5097 21.4903 96 48 96ZM48 2C73.4051 2 94 22.5949 94 48C94 73.4051 73.4051 94 48 94C22.5949 94 2 73.4051 2 48C2 22.5949 22.5949 2 48 2Z"></path><path fill-rule="evenodd" d="M46.9945 16C38.804 16.2514 31.3898 19.5764 25.8646 24.864L30.1166 29.116C34.5531 24.9131 40.4614 22.2498 46.9945 22.0027L46.9945 16ZM48.9955 22.0027L48.9955 16C57.186 16.2514 64.6102 19.5764 70.1354 24.864L65.8834 29.116C61.4469 24.9131 55.5286 22.2498 48.9955 22.0027ZM67.284 30.5466C71.2558 34.9319 73.7581 40.67 73.9972 46.9941L80 46.9941C79.755 39.013 76.5902 31.7721 71.536 26.2947L67.284 30.5466ZM80 48.995L73.9972 48.995C73.8475 52.9538 72.8129 56.6862 71.0858 60L77.6889 60C79.0714 56.5848 79.8808 52.8769 80 48.995ZM18.3111 60L24.9142 60C23.187 56.6862 22.1525 52.9538 22.0028 48.995L16 48.995C16.1192 52.8769 16.9287 56.5848 18.3111 60ZM16 46.9941L22.0028 46.9941C22.242 40.67 24.7441 34.9319 28.716 30.5466L24.464 26.2947C19.4097 31.7721 16.245 39.013 16 46.9941Z" fill="#EDF5FF"></path><g><g filter="url(#filter_2_537)"><path d="M46.46 66.22L46.46 81.18L44.64 81.18L44.64 80.14L36.66 80.14L36.66 81.16L34.84 81.16L34.84 66.22L39.72 66.22L39.72 62.86L41.6 62.86L41.6 66.22L46.46 66.22ZM36.66 78.36L39.72 78.36L39.72 73.9L36.66 73.9L36.66 78.36ZM41.6 73.9L41.6 78.36L44.64 78.36L44.64 73.9L41.6 73.9ZM36.66 72.18L39.72 72.18L39.72 68.02L36.66 68.02L36.66 72.18ZM41.6 68.02L41.6 72.18L44.64 72.18L44.64 68.02L41.6 68.02ZM30.86 63.02Q32.94 64.48 34.3 65.88L32.94 67.24Q31.8 65.96 29.5 64.34L30.86 63.02ZM30.36 67.8Q32.34 69.22 33.76 70.7L32.4 72.06Q31.22 70.7 29 69.12L30.36 67.8ZM33.82 73.84Q32.56 77.68 31 81.04L29.24 80.26Q30.88 76.9 32.14 73.2L33.82 73.84ZM62.3 81.1L61.82 79.32L63.56 79.36Q64.36 79.36 64.36 78.3L64.36 65.44L56.84 65.44L56.84 63.68L66.2 63.68L66.2 78.82Q66.2 81.1 63.94 81.1L62.3 81.1ZM49.76 66.12L51.6 66.12L51.6 81.28L49.76 81.28L49.76 66.12ZM53.1 62.6Q54.48 64.22 55.54 66.16L53.84 67.06Q52.74 65.02 51.38 63.36L53.1 62.6Z" fill="#EDF5FF"></path></g></g><defs><linearGradient id="linear_border_2_530_0" x1="48" y1="96" x2="48" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#7EA2CF" stop-opacity="0.4"/><stop offset="0.2807" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="0.5394" stop-color="#7DA2CE"/><stop offset="0.7815" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="1" stop-color="#7DA2CE" stop-opacity="0.4"/></linearGradient><filter id="filter_2_537" x="29" y="62.60009765625" width="37.199951171875" height="19.679931640625" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="feFloodId_2_537"/><feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha_2_537"/><feOffset dx="0" dy="1"/><feComposite in2="hardAlpha_2_537" operator="out"/><feColorMatrix type="matrix" values="0 0 0 0 0 0 0 0 0 0.06274509803921569 0 0 0 0 0.1411764705882353 0 0 0 0.5 0"/><feBlend mode="normal" in2="feFloodId_2_537" result="dropShadow_1_2_537"/><feBlend mode="normal" in="SourceGraphic" in2="dropShadow_1_2_537" result="shape_2_537"/></filter></defs></svg>
''';

const _indicatorPointerSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="12" height="26" viewBox="0 0 12 26" fill="none"><path fill-rule="evenodd" d="M11.4271 19.1793L7.2259 0.974391C7.09428 0.404028 6.5864 0 6.00104 0C5.41569 0 4.90781 0.404028 4.77619 0.974391L0.575066 19.1793C-0.230173 22.6686 2.41997 26 6.00104 26C9.58212 26 12.2323 22.6686 11.4271 19.1793ZM6.00104 23C7.6579 23 9.00104 21.6569 9.00104 20C9.00104 18.3431 7.6579 17 6.00104 17C4.34419 17 3.00104 18.3431 3.00104 20C3.00104 21.6569 4.34419 23 6.00104 23Z" fill="#EDF5FF"></path></svg>
''';

enum _IndicatorType { steering, throttle }

class SteeringIndicatorRow extends StatelessWidget {
  const SteeringIndicatorRow({
    super.key,
    required this.steering,
    required this.throttle,
    this.itemCount = 1,
    this.size = 48,
    this.gap = 40,
  }) : assert(itemCount >= 1 && itemCount <= 2);

  final double steering;
  final double throttle;
  final int itemCount;
  final double size;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(itemCount, (index) {
        final indicatorType = itemCount == 2 && index == 1
            ? _IndicatorType.throttle
            : _IndicatorType.steering;
        final value = indicatorType == _IndicatorType.throttle
            ? -throttle
            : steering;
        return Padding(
          padding: EdgeInsets.only(right: index == itemCount - 1 ? 0 : gap),
          child: _SteeringIndicatorDial(
            size: size,
            value: value,
            type: indicatorType,
          ),
        );
      }),
    );
  }
}

class _SteeringIndicatorDial extends StatelessWidget {
  const _SteeringIndicatorDial({
    required this.size,
    required this.value,
    required this.type,
  });

  final double size;
  final double value;
  final _IndicatorType type;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(-1.0, 1.0);
    final targetTurns = clamped * (1 / 8); // +/-45deg
    final scale = size / 96;
    final pointerWidth = 12 * scale;
    final pointerHeight = 26 * scale;
    final pointerTop = 28 * scale;
    final pointerLeft = (size / 2) - (pointerWidth / 2);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          SvgPicture.string(
            type == _IndicatorType.throttle
                ? _throttleDialSvg
                : _indicatorDialSvg,
            width: size,
            height: size,
          ),
          Positioned(
            left: pointerLeft,
            top: pointerTop,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: targetTurns),
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              builder: (context, turns, child) {
                return Transform.rotate(
                  angle: turns * 2 * math.pi,
                  alignment: const Alignment(0, 7 / 10),
                  child: child,
                );
              },
              child: SvgPicture.string(
                _indicatorPointerSvg,
                width: pointerWidth,
                height: pointerHeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

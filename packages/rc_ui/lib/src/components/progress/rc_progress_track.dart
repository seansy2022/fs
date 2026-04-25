import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

enum RcProgressAxis { horizontal, vertical }

class RcProgressTrack extends StatelessWidget {
  const RcProgressTrack({
    super.key,
    required this.value,
    required this.max,
    int? controlMax,
    this.leftValue,
    this.rightValue,
    this.positiveValue,
    this.negativeValue,
    this.axis = RcProgressAxis.horizontal,
    this.highlightFill = true,
    this.showLabels = true,
    this.showUnsignedRange = false,
    this.absoluteLabels = false,
    this.reverseLabelSide = false,
    this.overlayVerticalLabels = false,
    this.showIntermediateLabels = true,
  }) : controlMax = controlMax ?? max;

  const RcProgressTrack.dashboard({
    super.key,
    required this.value,
    this.max = 120,
    int? controlMax,
    this.absoluteLabels = true,
    this.showLabels = true,
    this.showUnsignedRange = false,
    this.showIntermediateLabels = true,
  }) : axis = RcProgressAxis.horizontal,
       controlMax = controlMax ?? max,
       highlightFill = true,
       leftValue = null,
       rightValue = null,
       positiveValue = null,
       negativeValue = null,
       reverseLabelSide = false, // standard placement
       overlayVerticalLabels = false;

  const RcProgressTrack.horizontal({
    super.key,
    required this.value,
    required this.max,
    int? controlMax,
    this.leftValue,
    this.rightValue,
    this.showUnsignedRange = false,
    this.highlightFill = true,
    this.showLabels = true,
    this.absoluteLabels = false,
    this.showIntermediateLabels = true,
  }) : axis = RcProgressAxis.horizontal,
       controlMax = controlMax ?? max,
       positiveValue = null,
       negativeValue = null,
       reverseLabelSide = false,
       overlayVerticalLabels = false;

  const RcProgressTrack.vertical({
    super.key,
    required this.value,
    required this.max,
    int? controlMax,
    this.positiveValue,
    this.negativeValue,
    this.showLabels = true,
    this.absoluteLabels = false,
    this.reverseLabelSide = false, // mirrors to right if true
    this.overlayVerticalLabels = false,
    this.showIntermediateLabels = true,
  }) : axis = RcProgressAxis.vertical,
       controlMax = controlMax ?? max,
       leftValue = null,
       rightValue = null,
       highlightFill = true,
       showUnsignedRange = false;

  final double value;
  final int max;
  final int controlMax;
  final int? leftValue;
  final int? rightValue;
  final double? positiveValue;
  final double? negativeValue;
  final RcProgressAxis axis;
  final bool highlightFill;
  final bool showLabels;
  final bool showUnsignedRange;
  final bool absoluteLabels;
  final bool reverseLabelSide; // Labels on top/right
  final bool overlayVerticalLabels;
  final bool showIntermediateLabels;

  static const double trackThickness = 10.0;
  static const double textFontSize = 8.0;
  static const double textGap = 2.0;
  static const double verticalLabelGap = 4.0;
  static const Color _tickGray = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (axis == RcProgressAxis.horizontal) {
          final extra = showLabels ? (textGap + textFontSize) : 0.0;
          return SizedBox(
            width: constraints.maxWidth,
            height: trackThickness + 2 * extra,
            child: _buildHorizontal(constraints.maxWidth, extra),
          );
        } else {
          return SizedBox(
            height: constraints.maxHeight,
            child: _buildVertical(constraints.maxHeight),
          );
        }
      },
    );
  }

  Widget _buildHorizontal(double width, double extra) {
    final pivot = showUnsignedRange ? 0.0 : width / 2;
    final fills = _horizontalFills(width, pivot);
    final trackTop = extra;
    final labelTop = extra + trackThickness + textGap;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background
        Positioned(
          top: trackTop,
          left: 0,
          right: 0,
          height: trackThickness,
          child: Container(color: const Color(0xFF1B2D4D)),
        ),

        // Background Ticks: All except 0-tick (Center)
        ...List.generate(13, (i) {
          if (i == 6) return const SizedBox.shrink(); // Skip center tick here
          final frac = i / 12;
          final x = frac * width;
          return _tickH(x, trackTop, i);
        }),

        // Fills
        if (fills.$1 > 0)
          _fillH(
            left: pivot - fills.$1,
            width: fills.$1,
            top: trackTop,
            positive: false,
          ),
        if (fills.$2 > 0)
          _fillH(left: pivot, width: fills.$2, top: trackTop, positive: true),

        // Foreground Ticks: Only 0-tick (Center) to stay on top
        ...List.generate(1, (i) {
          final frac = 6 / 12;
          final x = frac * width;
          return _tickH(x, trackTop, 6);
        }),

        // Labels
        if (showLabels) ..._buildLabelsH(width, labelTop),
      ],
    );
  }

  Widget _buildVertical(double height) {
    final pivot = height / 2;
    final control = controlMax.toDouble();
    final display = max.toDouble();
    final v = value.clamp(-control, control);
    final topRaw = (positiveValue ?? (v >= 0 ? v : 0)).clamp(0.0, control);
    final bottomRaw = (negativeValue ?? (v < 0 ? -v : 0)).clamp(0.0, control);
    final topFill = pivot * (topRaw.abs() / display).clamp(0.0, 1.0);
    final bottomFill = pivot * (bottomRaw.abs() / display).clamp(0.0, 1.0);

    final track = SizedBox(
      width: trackThickness,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: trackThickness,
            child: Container(color: const Color(0xFF1B2D4D)),
          ),

          // Background Ticks: All except 0-tick (Center)
          ...List.generate(11, (i) {
            if (i == 5) return const SizedBox.shrink(); // Skip center tick here
            final fraction = i / 10;
            final y = fraction * height;
            return _tickV(y, i);
          }),

          // Fills
          if (topFill > 0)
            _fillV(top: pivot - topFill, height: topFill, positive: true),
          if (bottomFill > 0)
            _fillV(top: pivot, height: bottomFill, positive: false),

          // Foreground Ticks: Only 0-tick (Center) to stay on top
          ...List.generate(1, (i) {
            final fraction = 5 / 10;
            final y = fraction * height;
            return _tickV(y, 5);
          }),
        ],
      ),
    );

    if (!showLabels) return track;

    final labels = _buildLabelsV(height);
    if (overlayVerticalLabels) {
      final overlayOffsetX = reverseLabelSide
          ? (trackThickness + verticalLabelGap)
          : -(trackThickness + verticalLabelGap);
      return SizedBox(
        width: trackThickness,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: track),
            Positioned.fill(
              child: IgnorePointer(
                child: OverflowBox(
                  alignment: Alignment.center,
                  minWidth: 0,
                  maxWidth: double.infinity,
                  child: Transform.translate(
                    offset: Offset(overlayOffsetX, 0),
                    child: labels,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reverseLabelSide
          ? [track, const SizedBox(width: verticalLabelGap), labels]
          : [labels, const SizedBox(width: verticalLabelGap), track],
    );
  }

  (double, double) _horizontalFills(double width, double pivot) {
    final control = controlMax.toDouble();
    final display = max.toDouble();
    if (showUnsignedRange) {
      final single = value.clamp(0, control);
      final fill = _withMinVisibleFill(
        width * (single / display).clamp(0.0, 1.0),
        isNonZero: single > 0,
      );
      return (0, fill);
    }
    final dual = leftValue != null && rightValue != null;
    if (dual) {
      final left = leftValue!.clamp(0, controlMax) / display;
      final right = rightValue!.clamp(0, controlMax) / display;
      return (
        _withMinVisibleFill(pivot * left, isNonZero: left > 0),
        _withMinVisibleFill(pivot * right, isNonZero: right > 0),
      );
    }
    final single = value.clamp(-control, control);
    final fill = _withMinVisibleFill(
      pivot * (single.abs() / display).clamp(0.0, 1.0),
      isNonZero: single != 0,
    );
    if (single < 0) return (fill, 0);
    return (0, fill);
  }

  double _withMinVisibleFill(double fill, {required bool isNonZero}) {
    if (!isNonZero) return 0;
    if (fill >= 1) return fill;
    return 1;
  }

  Widget _fillH({
    required double left,
    required double width,
    required double top,
    required bool positive,
  }) {
    return Positioned(
      top: top,
      left: left,
      width: width,
      height: trackThickness,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: positive
              ? AppGradients.primary
              : AppGradients.primaryReverse,
        ),
      ),
    );
  }

  Widget _fillV({
    required double top,
    required double height,
    required bool positive,
  }) {
    return Positioned(
      top: top,
      left: 0,
      width: trackThickness,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: positive
              ? AppGradients.primaryVertical
              : AppGradients.primaryVerticalReverse,
        ),
      ),
    );
  }

  Widget _tickH(double x, double trackTop, int i) {
    // Indices for 13 ticks: 0 (-120), 1 (-100), 6 (0), 11 (100), 12 (120)
    final isCenter = i == 6;
    final isEnd = i == 0 || i == 12;
    final is100 = i == 1 || i == 11;

    double h = 2.0;
    if (isCenter)
      h = 10.0;
    else if (isEnd)
      h = 0.0;
    else if (is100)
      h = 4.0;

    final double top;
    if (isCenter) {
      // 0 刻度居中对齐
      top = trackTop + (trackThickness - h) / 2 - 0.5;
    } else {
      // 其它刻度维持之前的“底部对齐”逻辑
      top = trackTop + trackThickness - h;
    }

    final displayX = x.clamp(0.0, double.infinity) - (isEnd && i == 12 ? 2 : 0);
    const tickStroke = 0.25;
    const tickTotalWidth = tickStroke * 2;
    final tickLeft = isCenter ? displayX - (tickTotalWidth / 2) : displayX;
    final tickMainColor = _tickGray.withValues(alpha: isCenter ? 0.7 : 1);
    final tickShadowColor = const Color(
      0xFF001024,
    ).withValues(alpha: isCenter ? 0.7 : 1);

    return Positioned(
      left: tickLeft,
      top: top,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: tickStroke, height: h, color: tickMainColor),
          Container(width: tickStroke, height: h, color: tickShadowColor),
        ],
      ),
    );
  }

  Widget _tickV(double y, int i) {
    final isCenter = i == 5;
    final isEnd = i == 0 || i == 10;
    final is100 = i == 1 || i == 9;

    double w = 2.0;
    if (isCenter)
      w = 10.0;
    else if (isEnd)
      w = 0.0;
    else if (is100)
      w = 4.0;

    final left = trackThickness - w;
    final displayY =
        y.clamp(0.0, double.infinity) -
        (isEnd && i == 10 ? 2 : 0) -
        (isCenter ? 0.5 : 0);
    final tickMainColor = _tickGray.withValues(alpha: isCenter ? 0.7 : 1);
    final tickShadowColor = const Color(
      0xFF001024,
    ).withValues(alpha: isCenter ? 0.7 : 1);

    return Positioned(
      top: displayY,
      left: left,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 0.2, width: w, color: tickMainColor),
          Container(height: 1, width: w, color: tickShadowColor),
        ],
      ),
    );
  }

  List<Widget> _buildLabelsH(double width, double labelTop) {
    if (showUnsignedRange) {
      final texts = [
        '0',
        '${(max * 0.25).round()}',
        '${(max * 0.5).round()}',
        '${(max * 0.75).round()}',
        '$max',
      ];
      return List.generate(5, (i) {
        final frac = [0.0, 0.25, 0.5, 0.75, 1.0][i];
        return _buildLabelItem(width, labelTop, texts[i], frac);
      });
    }

    // Dual/Signed range
    final List<String> texts;
    final List<double> fractions;

    if (max == 100) {
      // Clean 100-0-100 style
      texts = [absoluteLabels ? '100' : '-100', '0', '100'];
      fractions = [0.0, 0.5, 1.0];
    } else {
      final val1 = absoluteLabels ? '$max' : '-$max';
      final val2Val = (max == 120) ? 100 : (max * 0.8).round();
      final val2 = absoluteLabels ? '$val2Val' : '-$val2Val';
      texts = [val1, val2, '0', '$val2Val', '$max'];
      fractions = [0.0, 1 / 12, 6 / 12, 11 / 12, 1.0];
    }

    return List.generate(texts.length, (i) {
      return _buildLabelItem(width, labelTop, texts[i], fractions[i]);
    });
  }

  Widget _buildLabelItem(
    double width,
    double labelTop,
    String text,
    double frac,
  ) {
    final align = frac == 0.0
        ? Alignment.centerLeft
        : frac == 1.0
        ? Alignment.centerRight
        : Alignment(frac * 2 - 1, 0.0);

    return Positioned(
      left: 0,
      right: 0,
      top: labelTop,
      child: Align(
        alignment: align,
        child: Text(text, style: _labelStyle),
      ),
    );
  }

  Widget _buildLabelsV(double height) {
    final align = reverseLabelSide
        ? Alignment.centerLeft
        : Alignment.centerRight;
    final List<(String, double)> labels;
    if (max == 100) {
      final bottom = absoluteLabels ? '100' : '-100';
      labels = [('100', 0.0), ('0', 0.5), (bottom, 1.0)];
    } else if (!showIntermediateLabels) {
      final bottom = absoluteLabels ? '$max' : '-$max';
      labels = [('$max', 0.0), ('0', 0.5), (bottom, 1.0)];
    } else {
      final v80 = (max == 120) ? 100 : (max * 0.8).round();
      final bottom80 = absoluteLabels ? '$v80' : '-$v80';
      final bottomMax = absoluteLabels ? '$max' : '-$max';
      labels = [
        ('$max', 0.0),
        ('$v80', 0.1),
        ('0', 0.5),
        (bottom80, 0.9),
        (bottomMax, 1.0),
      ];
    }

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: labels.map((item) {
          final text = item.$1;
          final frac = item.$2;
          final y = frac * 2 - 1;
          final zeroNudgeX = (!reverseLabelSide && text == '0') ? 10.0 : 0.0;

          return Align(
            alignment: Alignment(align.x, y),
            child: Transform.translate(
              offset: Offset(zeroNudgeX, 0),
              child: Text(text, style: _labelStyle),
            ),
          );
        }).toList(),
      ),
    );
  }

  TextStyle get _labelStyle => const TextStyle(
    color: Color(0xFF465D7A),
    fontFamily: AppFonts.roboto,
    fontSize: textFontSize,
    height: 1,
  );
}

import 'package:flutter/material.dart';

import 'four_c_layout_option.dart';

class FourCLayoutGrid extends StatelessWidget {
  const FourCLayoutGrid({
    super.key,
    required this.ratio,
    required this.direction,
    required this.onModeChange,
  });

  final int ratio;
  final String direction;
  final void Function(int ratio, String direction) onModeChange;

  int _clamp(int v) => v.clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    final selected = _currentMode();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 150,
                child: _option(FourCLayoutMode.frontSame, selected),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 150,
                child: _option(FourCLayoutMode.rearOpposite, selected),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 150,
                child: _option(FourCLayoutMode.rearSame, selected),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 150,
                child: _option(FourCLayoutMode.frontOpposite, selected),
              ),
            ),
          ],
        ),
      ],
    );
  }

  FourCLayoutMode? _currentMode() {
    if (direction == '4WS_REAR_OPPOSITE') return FourCLayoutMode.rearOpposite;
    if (direction == '4WS_REAR_SAME') return FourCLayoutMode.rearSame;
    if (direction == '4WS_FRONT_OPPOSITE') {
      return FourCLayoutMode.frontOpposite;
    }
    if (direction == '4WS_FRONT_SAME') return FourCLayoutMode.frontSame;
    // Backward compatibility for old state values.
    if (direction == 'OPPOSITE') return FourCLayoutMode.frontOpposite;
    return null;
  }

  Widget _option(FourCLayoutMode mode, FourCLayoutMode? selected) {
    return FourCLayoutOption(
      mode: mode,
      selected: mode == selected,
      onTap: () => _select(mode),
    );
  }

  void _select(FourCLayoutMode mode) {
    final mag = ratio.clamp(0, 100);
    final next = switch (mode) {
      FourCLayoutMode.frontSame => (_clamp(mag), '4WS_FRONT_SAME'),
      FourCLayoutMode.frontOpposite => (_clamp(mag), '4WS_FRONT_OPPOSITE'),
      FourCLayoutMode.rearSame => (_clamp(mag), '4WS_REAR_SAME'),
      FourCLayoutMode.rearOpposite => (_clamp(mag), '4WS_REAR_OPPOSITE'),
    };
    onModeChange(next.$1, next.$2);
  }
}

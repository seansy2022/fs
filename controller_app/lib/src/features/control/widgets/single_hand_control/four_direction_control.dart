import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/localization/app_localizations.dart';

/// 四方向控制区一次手势输出的方向与油门值，范围均为 -1 到 1。
class FourDirectionValue {
  const FourDirectionValue({required this.steering, required this.throttle});

  final double steering;
  final double throttle;
}

enum _DirectionRegion { forward, reverse, left, right }

const fourDirectionThumbKey = ValueKey<String>('four-direction-thumb');
/// 单手四方向控件的外框边长；固定与隐藏模式共用，避免视觉尺寸不一致。
const singleHandControlSide = 180.0;
const _directionCellSide = 80.0;

/// 返回单个方向单元的边长；标准 200px 控制区固定使用 90px 单元。
double fourDirectionCellSideFor(Size controlSize) {
  return math.min(
    _directionCellSide,
    math.min(controlSize.width, controlSize.height) / 2,
  );
}

/// 在居中的 2×2 网格内计算四个方向单元的位置。
Offset _directionCellOffset(
  _DirectionRegion region,
  Size controlSize,
  double cellSide,
) {
  final gridLeft = (controlSize.width - cellSide * 2) / 2;
  final gridTop = (controlSize.height - cellSide * 2) / 2;
  return switch (region) {
    _DirectionRegion.forward => Offset(gridLeft + cellSide / 2, gridTop),
    _DirectionRegion.reverse => Offset(
      gridLeft + cellSide / 2,
      gridTop + cellSide,
    ),
    _DirectionRegion.left => Offset(gridLeft, gridTop + cellSide / 2),
    _DirectionRegion.right => Offset(
      gridLeft + cellSide,
      gridTop + cellSide / 2,
    ),
  };
}

/// 单手模式的中间四方向控制区。
///
/// 一个单方向 SVG 经缩小和旋转后组成上、下、左、右四个方向；高亮 SVG
/// 只覆盖当前有输入值的方向。组件只负责方向、油门和触摸圆点，不关心
/// 左右手布局与微调控件。
class FourDirectionControl extends StatefulWidget {
  const FourDirectionControl({super.key, required this.onChanged});

  static const normalAsset = 'lib/src/assets/svg/single_hand_normal.svg';
  static const activeAsset = 'lib/src/assets/svg/single_hand_active.svg';

  final ValueChanged<FourDirectionValue> onChanged;

  @override
  State<FourDirectionControl> createState() => _FourDirectionControlState();
}

class _FourDirectionControlState extends State<FourDirectionControl> {
  Offset _value = Offset.zero;
  bool _touching = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Listener(
          behavior: HitTestBehavior.opaque,
          // 直接监听指针，按下时立即显示圆点和高亮，不依赖拖拽识别阈值。
          onPointerDown: (event) => _updateValue(event.localPosition, size),
          onPointerMove: (event) => _updateValue(event.localPosition, size),
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          child: Semantics(
            label: AppText.tr('四方向控制'),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 普通态始终绘制四次，组成完整的四方向控制视觉。
                for (final region in _DirectionRegion.values)
                  _buildDirection(
                    region,
                    FourDirectionControl.normalAsset,
                    size,
                  ),
                // 有值的方向再覆盖高亮图，支持两个方向同时高亮。
                for (final region in _activeRegions)
                  _buildDirection(
                    region,
                    FourDirectionControl.activeAsset,
                    size,
                  ),
                if (_touching) _buildThumb(size),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 只要对应通道的值不为 0 即高亮；两个通道可同时高亮。
  Iterable<_DirectionRegion> get _activeRegions sync* {
    if (_value.dy > 0) yield _DirectionRegion.forward;
    if (_value.dy < 0) yield _DirectionRegion.reverse;
    if (_value.dx < 0) yield _DirectionRegion.left;
    if (_value.dx > 0) yield _DirectionRegion.right;
  }

  /// 将单方向 SVG 缩小后旋转到目标方位，避免单个箭头填满整个控制区。
  Widget _buildDirection(
    _DirectionRegion region,
    String asset,
    Size controlSize,
  ) {
    // 四个方向按 100×100 单元拼接；窄容器才等比收缩以避免溢出。
    final cellSide = fourDirectionCellSideFor(controlSize);
    final cellSize = Size.square(cellSide);
    final position = _directionCellOffset(region, controlSize, cellSide);
    final angle = switch (region) {
      _DirectionRegion.left => 0.0,
      _DirectionRegion.forward => math.pi / 2,
      _DirectionRegion.right => math.pi,
      _DirectionRegion.reverse => -math.pi / 2,
    };
    final state = asset == FourDirectionControl.activeAsset
        ? 'highlight'
        : 'normal';

    return Positioned(
      key: ValueKey<String>('four-direction-$state-${region.name}'),
      left: position.dx,
      top: position.dy,
      width: cellSize.width,
      height: cellSize.height,
      child: Transform.rotate(
        angle: angle,
        // 高亮素材的原始箭头朝右，普通素材朝左；先翻转再旋转才能重合。
        child: asset == FourDirectionControl.activeAsset
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(-1, 1, 1),
                child: SvgPicture.asset(asset, fit: BoxFit.fill),
              )
            : SvgPicture.asset(asset, fit: BoxFit.fill),
      ),
    );
  }

  /// 将触点归一化为方向和油门值；横向是方向，向上为正油门。
  void _updateValue(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final steering = ((localPosition.dx - center.dx) / (size.width / 2))
        .clamp(-1.0, 1.0)
        .toDouble();
    final throttle = (-(localPosition.dy - center.dy) / (size.height / 2))
        .clamp(-1.0, 1.0)
        .toDouble();
    setState(() {
      _touching = true;
      _value = Offset(steering, throttle);
    });
    widget.onChanged(
      FourDirectionValue(steering: steering, throttle: throttle),
    );
  }

  /// 圆点的中心和输出共用归一化坐标，始终限制在四方向区内。
  Widget _buildThumb(Size size) {
    const diameter = 44.0;
    final center = Offset(
      (size.width / 2) + (_value.dx * ((size.width - diameter) / 2)),
      (size.height / 2) - (_value.dy * ((size.height - diameter) / 2)),
    );
    return Positioned(
      key: fourDirectionThumbKey,
      left: center.dx - (diameter / 2),
      top: center.dy - (diameter / 2),
      width: diameter,
      height: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFEDF5FF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF001024), width: 1.5),
        ),
      ),
    );
  }

  /// 松手时清空方向和油门，使所有方向立即恢复未高亮。
  void _release() {
    setState(() {
      _touching = false;
      _value = Offset.zero;
    });
    widget.onChanged(const FourDirectionValue(steering: 0, throttle: 0));
  }
}

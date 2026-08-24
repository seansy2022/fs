import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 双手方向控制中的单向箭头按钮；按住输出方向，松手自动回中。
class DirectionalSteeringButton extends StatefulWidget {
  const DirectionalSteeringButton({
    super.key,
    required this.direction,
    required this.onChanged,
  }) : assert(direction == -1 || direction == 1);

  /// -1 表示左转，1 表示右转。
  final double direction;
  final ValueChanged<double> onChanged;

  @override
  State<DirectionalSteeringButton> createState() =>
      _DirectionalSteeringButtonState();
}

class _DirectionalSteeringButtonState extends State<DirectionalSteeringButton> {
  static const _activeAsset = 'packages/rc_ui/lib/src/assets/assets/点击.svg';
  static const _inactiveAsset =
      'packages/rc_ui/lib/src/assets/assets/点击_wei.svg';
  static const _thumbAsset = 'packages/rc_ui/lib/src/assets/assets/手柄点.svg';
  static const _controlSize = 100.0;
  static const _thumbSize = 44.0;
  static const _thumbRange = _controlSize - _thumbSize;
  static const _epsilon = 0.0001;

  double _value = 0;
  double _thumbLeft = 0;
  bool _isDragging = false;

  /// 根据手指横向位置更新方向比例，并让小圆点跟随手指移动。
  void _updateValue(Offset localPosition) {
    final clampedDx = localPosition.dx.clamp(0.0, _controlSize).toDouble();
    final progress = (clampedDx / _controlSize).clamp(0.0, 1.0);
    final nextValue = widget.direction > 0 ? progress : -(1.0 - progress);
    final nextThumbLeft = progress * _thumbRange;

    if ((nextValue - _value).abs() < _epsilon &&
        (nextThumbLeft - _thumbLeft).abs() < _epsilon) {
      return;
    }
    setState(() {
      _isDragging = true;
      _value = nextValue;
      _thumbLeft = nextThumbLeft;
    });
    widget.onChanged(_value);
  }

  /// 开始拖动时建立初始输出，避免等待后续移动事件才显示手柄点。
  void _startDrag(Offset localPosition) {
    if (!_isDragging) {
      setState(() {
        _isDragging = true;
      });
    }
    _updateValue(localPosition);
  }

  /// 松手或系统取消手势时回中，保证不会遗留方向输出。
  void _reset() {
    final hasOutput =
        _isDragging || _value.abs() >= _epsilon || _thumbLeft != 0;
    if (hasOutput) {
      setState(() {
        _isDragging = false;
        _value = 0;
        _thumbLeft = 0;
      });
    }
    widget.onChanged(0);
  }

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.direction < 0;
    final arrow = SvgPicture.asset(
      _isDragging ? _activeAsset : _inactiveAsset,
      key: ValueKey<String>(
        'directional-steering-asset-${isLeft ? 'left' : 'right'}',
      ),
      width: 100,
      height: 100,
      fit: BoxFit.contain,
    );
    return GestureDetector(
      key: ValueKey<String>(
        'directional-steering-${isLeft ? 'left' : 'right'}',
      ),
      behavior: HitTestBehavior.opaque,
      // 与双手方向控件保持一致：以手指横向拖动控制方向幅度。
      onPanStart: (details) => _startDrag(details.localPosition),
      onPanUpdate: (details) => _updateValue(details.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: SizedBox(
        width: _controlSize,
        height: _controlSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 原 SVG 为右向箭头，左侧按钮仅镜像资源，保持默认态与点亮态一致。
            isLeft
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(-1, 1, 1),
                    child: arrow,
                  )
                : arrow,
            // 与垂直方向控件一致，拖动期间小圆点按横向位置跟随手指。
            if (_isDragging)
              Positioned(
                key: ValueKey<String>(
                  'directional-steering-thumb-position-${isLeft ? 'left' : 'right'}',
                ),
                left: _thumbLeft,
                top: (_controlSize - _thumbSize) / 2,
                child: SvgPicture.asset(
                  _thumbAsset,
                  key: ValueKey<String>(
                    'directional-steering-thumb-${isLeft ? 'left' : 'right'}',
                  ),
                  width: _thumbSize,
                  height: _thumbSize,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

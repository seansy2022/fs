import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:rc_ui/src/core/app_assets.dart';
import 'package:rc_ui/src/components/value_control/control_value_widget.dart';
import 'tank_control_parts.dart';

class TankControl extends StatelessWidget {
  const TankControl({
    super.key,
    required this.selectedChannel,
    required this.ratio,
    required this.direction,
    required this.forwardRatio,
    required this.backwardRatio,
    required this.leftRatio,
    required this.rightRatio,
    required this.onControlChange,
  });

  final String selectedChannel;
  final int ratio;
  final String direction;
  final int forwardRatio;
  final int backwardRatio;
  final int leftRatio;
  final int rightRatio;
  final void Function(int ratio, String direction) onControlChange;

  static const _step = 1;
  static const _maxValue = 100;
  static const _trackHeight = 220.0;
  static const _trackToCenterGap = 12.0;

  int _next(int current, bool plus) =>
      (current + (plus ? _step : -_step)).clamp(0, _maxValue);

  void _toForward(bool plus) {
    onControlChange(_next(forwardRatio, plus), 'SAME');
  }

  void _toBackward(bool plus) {
    onControlChange(-_next(backwardRatio, plus), 'SAME');
  }

  void _toTurn(bool left, bool plus) {
    final current = left ? leftRatio : rightRatio;
    final next = _next(current, plus);
    onControlChange(left ? -next : next, 'OPPOSITE');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF001024),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左转控制 - 垂直居中
          TankTurnControl(
            label: '左转',
            valueText: '$leftRatio%',
            onMinus: () => _toTurn(true, false),
            onPlus: () => _toTurn(true, true),
          ),
          // 左侧进度条 - 垂直居中
          SizedBox(width: _trackToCenterGap),
          SizedBox(
            height: _trackHeight,
            child: TankProgressTrack(
              topValue: forwardRatio,
              bottomValue: leftRatio,
            ),
          ),
          // SizedBox(width: 6),
          // 中间Column：前进 → 坦克 → 后退
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 前进
                  ControlValueWidget(
                    label: '前进',
                    valueText: '$forwardRatio%',
                    style: ControlValueStyle.horizontal,
                    onMinus: () => _toForward(false),
                    onPlus: () => _toForward(true),
                  ),
                  // 坦克图片
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 100,
                    height: 150,
                    child: SvgPicture.asset(
                      AppAssets.tank,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // 后退
                  const SizedBox(height: 18),
                  ControlValueWidget(
                    label: '后退',
                    valueText: '$backwardRatio%',
                    style: ControlValueStyle.horizontal,
                    onMinus: () => _toBackward(false),
                    onPlus: () => _toBackward(true),
                  ),
                ],
              ),
            ),
          ),
          // 右侧进度条 - 垂直居中
          // SizedBox(width: 4),
          SizedBox(
            height: _trackHeight,
            child: TankProgressTrack(
              topValue: rightRatio,
              bottomValue: backwardRatio,
              flipX: true,
            ),
          ),
          // 右转控制 - 垂直居中
          SizedBox(width: _trackToCenterGap),
          TankTurnControl(
            label: '右转',
            valueText: '$rightRatio%',
            onMinus: () => _toTurn(false, false),
            onPlus: () => _toTurn(false, true),
          ),
        ],
      ),
    );
  }
}

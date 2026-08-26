import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

import 'four_direction_control.dart';

/// 右手单手控制：油门微调在右侧，方向微调在下方。
class SingleHandRightControl extends StatelessWidget {
  const SingleHandRightControl({
    super.key,
    required this.steeringTrim,
    required this.throttleTrim,
    required this.showTrimButtons,
    this.showTrims = true,
    required this.onControlChanged,
    required this.onSteeringTrimChanged,
    required this.onThrottleTrimChanged,
  });

  final int steeringTrim;
  final int throttleTrim;
  final bool showTrimButtons;
  final bool showTrims;
  final ValueChanged<FourDirectionValue> onControlChanged;
  final ValueChanged<int> onSteeringTrimChanged;
  final ValueChanged<int> onThrottleTrimChanged;

  @override
  Widget build(BuildContext context) {
    return _SingleHandControlLayout(
      rightHand: true,
      steeringTrim: steeringTrim,
      throttleTrim: throttleTrim,
      showTrimButtons: showTrimButtons,
      showTrims: showTrims,
      onControlChanged: onControlChanged,
      onSteeringTrimChanged: onSteeringTrimChanged,
      onThrottleTrimChanged: onThrottleTrimChanged,
    );
  }
}

/// 左手单手控制：油门微调在左侧，方向微调在下方。
class SingleHandLeftControl extends StatelessWidget {
  const SingleHandLeftControl({
    super.key,
    required this.steeringTrim,
    required this.throttleTrim,
    required this.showTrimButtons,
    this.showTrims = true,
    required this.onControlChanged,
    required this.onSteeringTrimChanged,
    required this.onThrottleTrimChanged,
  });

  final int steeringTrim;
  final int throttleTrim;
  final bool showTrimButtons;
  final bool showTrims;
  final ValueChanged<FourDirectionValue> onControlChanged;
  final ValueChanged<int> onSteeringTrimChanged;
  final ValueChanged<int> onThrottleTrimChanged;

  @override
  Widget build(BuildContext context) {
    return _SingleHandControlLayout(
      rightHand: false,
      steeringTrim: steeringTrim,
      throttleTrim: throttleTrim,
      showTrimButtons: showTrimButtons,
      showTrims: showTrims,
      onControlChanged: onControlChanged,
      onSteeringTrimChanged: onSteeringTrimChanged,
      onThrottleTrimChanged: onThrottleTrimChanged,
    );
  }
}

/// 左右手布局的共享实现，仅交换四方向区和油门微调的位置。
class _SingleHandControlLayout extends StatelessWidget {
  const _SingleHandControlLayout({
    required this.rightHand,
    required this.steeringTrim,
    required this.throttleTrim,
    required this.showTrimButtons,
    required this.showTrims,
    required this.onControlChanged,
    required this.onSteeringTrimChanged,
    required this.onThrottleTrimChanged,
  });

  static const _edge = 20.0;
  static const _gap = 8.0;
  static const _buttonSize = 24.0;
  static const _trimReservedSize = (_buttonSize * 2) + (_gap * 2);
  static const _designControlSide = singleHandControlSide;
  static const _minimumControlSide = 84.0;

  final bool rightHand;
  final int steeringTrim;
  final int throttleTrim;
  final bool showTrimButtons;
  final bool showTrims;
  final ValueChanged<FourDirectionValue> onControlChanged;
  final ValueChanged<int> onSteeringTrimChanged;
  final ValueChanged<int> onThrottleTrimChanged;

  @override
  Widget build(BuildContext context) {
    if (!showTrims) {
      return Align(
        alignment: rightHand ? Alignment.bottomRight : Alignment.bottomLeft,
        child: SizedBox(
          width: _designControlSide,
          height: _designControlSide,
          child: FourDirectionControl(onChanged: onControlChanged),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(
        left: rightHand ? 0 : _edge,
        right: rightHand ? _edge : 0,
        bottom: _edge,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 微调总长度与二维区边长一致，小屏时三部分同步缩小。
          final availableSide = math.min(
            constraints.maxWidth - (_buttonSize + _gap),
            constraints.maxHeight - (_buttonSize + _gap),
          );
          final controlSide = availableSide
              .clamp(_minimumControlSide, _designControlSide)
              .toDouble();
          final trimTrack = controlSide - _trimReservedSize;
          final groupSide = controlSide + _gap + _buttonSize;
          final controlLeft = rightHand ? 0.0 : _buttonSize + _gap;

          return Align(
            alignment: rightHand ? Alignment.bottomRight : Alignment.bottomLeft,
            child: SizedBox(
              width: groupSide,
              height: groupSide,
              child: Stack(
                children: [
                  Positioned(
                    left: controlLeft,
                    top: 0,
                    width: controlSide,
                    height: controlSide,
                    child: FourDirectionControl(onChanged: onControlChanged),
                  ),
                  Positioned(
                    left: rightHand ? controlSide + _gap : 0,
                    top: 0,
                    child: _buildThrottleTrim(trimTrack),
                  ),
                  Positioned(
                    left: controlLeft,
                    top: controlSide + _gap,
                    child: _buildSteeringTrim(trimTrack),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建油门微调，保持 -60 至 60 的步进范围。
  Widget _buildThrottleTrim(double trackMain) {
    return RCControllSider(
      direction: RCControllSiderDirection.vertical,
      initialValue: throttleTrim / 60,
      step: 0.02,
      trackMain: trackMain,
      enabled: showTrimButtons,
      showButtons: showTrimButtons,
      lockSignUntilRelease: true,
      onChanged: (value) => onThrottleTrimChanged((value * 60).round()),
    );
  }

  /// 构建方向微调，保持 -60 至 60 的步进范围。
  Widget _buildSteeringTrim(double trackMain) {
    return RCControllSider(
      direction: RCControllSiderDirection.horizontal,
      initialValue: steeringTrim / 60,
      step: 0.02,
      trackMain: trackMain,
      enabled: showTrimButtons,
      showButtons: showTrimButtons,
      onChanged: (value) => onSteeringTrimChanged((value * 60).round()),
    );
  }
}

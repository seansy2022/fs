import 'channel_output_mapper.dart';

class TankMixRatios {
  const TankMixRatios({
    required this.forward,
    required this.reverse,
    required this.leftTurn,
    required this.rightTurn,
  });

  final double forward;
  final double reverse;
  final double leftTurn;
  final double rightTurn;
}

class TankMixOutput {
  const TankMixOutput({required this.ch1Us, required this.ch2Us});

  final int ch1Us;
  final int ch2Us;
}

/// 将已校准的油门和方向 PWM 转换为两条履带输出。
TankMixOutput mixTankOutputs({
  required int throttleUs,
  required int steeringUs,
  required PrimaryChannelCalibration ch1,
  required PrimaryChannelCalibration ch2,
  required TankMixRatios ratios,
}) {
  final throttleDelta = throttleUs - ch1.centerUs;
  final steeringDelta = ch2.centerUs - steeringUs;
  final driveRatio = throttleDelta >= 0 ? ratios.forward : ratios.reverse;
  final turnRatio = steeringDelta >= 0 ? ratios.leftTurn : ratios.rightTurn;
  final drive = throttleDelta * (driveRatio.clamp(0, 100) / 100);
  final turn = steeringDelta * (turnRatio.clamp(0, 100) / 100);
  return TankMixOutput(
    ch1Us: ch1.clamp((ch1.centerUs + drive + turn).round()),
    ch2Us: ch2.clamp((ch2.centerUs + drive - turn).round()),
  );
}

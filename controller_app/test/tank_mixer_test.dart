import 'package:controller_app/src/features/control/controllers/channel_output_mapper.dart';
import 'package:controller_app/src/features/control/controllers/tank_mixer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final channel = calibratePrimaryChannel(
    lowPercent: -100,
    centerOffsetUs: 0,
    highPercent: 100,
  );
  const ratios = TankMixRatios(
    forward: 100,
    reverse: 100,
    leftTurn: 100,
    rightTurn: 100,
  );

  test('mixes forward and left turn', () {
    final output = mixTankOutputs(
      throttleUs: 1700,
      steeringUs: 1300,
      ch1: channel,
      ch2: channel,
      ratios: const TankMixRatios(
        forward: 100,
        reverse: 100,
        leftTurn: 50,
        rightTurn: 100,
      ),
    );

    expect(output.ch1Us, 1600);
    expect(output.ch2Us, 1800);
  });

  test('mixes reverse and right turn', () {
    final output = mixTankOutputs(
      throttleUs: 1300,
      steeringUs: 1700,
      ch1: channel,
      ch2: channel,
      ratios: ratios,
    );

    expect(output.ch1Us, 1500);
    expect(output.ch2Us, 1100);
  });

  test('bounds each track independently', () {
    final output = mixTankOutputs(
      throttleUs: 2000,
      steeringUs: 1000,
      ch1: channel,
      ch2: channel,
      ratios: ratios,
    );

    expect(output.ch1Us, 1500);
    expect(output.ch2Us, 2000);
  });

  test('uses the matching ratio for pure left and right turns', () {
    const turnRatios = TankMixRatios(
      forward: 100,
      reverse: 100,
      leftTurn: 50,
      rightTurn: 25,
    );

    final left = mixTankOutputs(
      throttleUs: 1500,
      steeringUs: 1300,
      ch1: channel,
      ch2: channel,
      ratios: turnRatios,
    );
    final right = mixTankOutputs(
      throttleUs: 1500,
      steeringUs: 1700,
      ch1: channel,
      ch2: channel,
      ratios: turnRatios,
    );

    expect((left.ch1Us, left.ch2Us), (1400, 1600));
    expect((right.ch1Us, right.ch2Us), (1550, 1450));
  });

  test('applies negative tank mixing ratios', () {
    final output = mixTankOutputs(
      throttleUs: 1700,
      steeringUs: 1500,
      ch1: channel,
      ch2: channel,
      ratios: const TankMixRatios(
        forward: -50,
        reverse: 100,
        leftTurn: 100,
        rightTurn: 100,
      ),
    );

    expect(output.ch1Us, 1400);
    expect(output.ch2Us, 1400);
  });
}

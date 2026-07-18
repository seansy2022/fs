import 'package:controller_app/src/features/control/controllers/channel_output_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('channelPercentToUs keeps the legacy percent-to-us conversion', () {
    expect(channelPercentToUs(-100), 1000);
    expect(channelPercentToUs(0), 1500);
    expect(channelPercentToUs(100), 2000);
  });

  test('auxChannelPercentToUs supports extended aux travel', () {
    expect(auxChannelPercentToUs(-120), 900);
    expect(auxChannelPercentToUs(-100), 1000);
    expect(auxChannelPercentToUs(0), 1500);
    expect(auxChannelPercentToUs(100), 2000);
    expect(auxChannelPercentToUs(120), 2100);
  });

  test('mapControlInputToUs keeps default mapping for default settings', () {
    expect(
      mapControlInputToUs(
        input: -1,
        lowPercent: -100,
        centerPercent: 0,
        highPercent: 100,
      ),
      1000,
    );
    expect(
      mapControlInputToUs(
        input: 0,
        lowPercent: -100,
        centerPercent: 0,
        highPercent: 100,
      ),
      1500,
    );
    expect(
      mapControlInputToUs(
        input: 1,
        lowPercent: -100,
        centerPercent: 0,
        highPercent: 100,
      ),
      2000,
    );
  });

  test('mapControlInputToUs interpolates negative and positive segments', () {
    expect(
      mapControlInputToUs(
        input: -0.5,
        lowPercent: -50,
        centerPercent: 0,
        highPercent: 50,
      ),
      1375,
    );
    expect(
      mapControlInputToUs(
        input: 0.5,
        lowPercent: -50,
        centerPercent: 0,
        highPercent: 50,
      ),
      1625,
    );
  });

  test('mapSteeringInputToUs applies trim after channel mapping', () {
    expect(
      mapSteeringInputToUs(
        steering: 0,
        lowPercent: -100,
        centerPercent: 10,
        highPercent: 100,
        trimStep: 2,
      ),
      1514,
    );
  });

  test('mapThrottleInputToUs maps positive throttle to higher PWM', () {
    expect(
      mapThrottleInputToUs(
        throttle: 1,
        lowPercent: -50,
        centerPercent: -1,
        highPercent: 80,
      ),
      1899,
    );
    expect(
      mapThrottleInputToUs(
        throttle: 0,
        lowPercent: -50,
        centerPercent: -1,
        highPercent: 80,
      ),
      1499,
    );
    expect(
      mapThrottleInputToUs(
        throttle: -1,
        lowPercent: -50,
        centerPercent: -1,
        highPercent: 80,
      ),
      1250,
    );
  });

  test(
    'mapThrottleInputToUs increments CH1 throttle trim upward by plus steps',
    () {
      final outputs = [0.0, 0.1, 0.2, 0.3]
          .map(
            (throttle) => mapThrottleInputToUs(
              throttle: throttle,
              lowPercent: -100,
              centerPercent: 0,
              highPercent: 100,
            ),
          )
          .toList();

      expect(outputs, <int>[1500, 1550, 1600, 1650]);
    },
  );

  test('primary calibration supports extended endpoints', () {
    final calibration = calibratePrimaryChannel(
      lowPercent: -120,
      centerOffsetUs: 0,
      highPercent: 120,
    );

    expect(calibration.lowUs, 900);
    expect(calibration.centerUs, 1500);
    expect(calibration.highUs, 2100);
  });

  test('primary calibration bounds a positive center offset', () {
    final calibration = calibratePrimaryChannel(
      lowPercent: -100,
      centerOffsetUs: 100,
      highPercent: 100,
    );

    expect(calibration.lowUs, 1100);
    expect(calibration.centerUs, 1600);
    expect(calibration.highUs, 2000);
  });

  test('reverses final primary PWM around 1500 us', () {
    expect(reversePrimaryOutputAroundCenter(900), 2100);
    expect(reversePrimaryOutputAroundCenter(1000), 2000);
    expect(reversePrimaryOutputAroundCenter(1500), 1500);
    expect(reversePrimaryOutputAroundCenter(2000), 1000);
    expect(reversePrimaryOutputAroundCenter(2100), 900);
  });
}

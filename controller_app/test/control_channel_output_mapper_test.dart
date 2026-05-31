import 'package:controller_app/src/features/control/controllers/channel_output_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('channelPercentToUs keeps the legacy percent-to-us conversion', () {
    expect(channelPercentToUs(-100), 1000);
    expect(channelPercentToUs(0), 1500);
    expect(channelPercentToUs(100), 2000);
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
      1554,
    );
  });

  test('mapThrottleInputToUs preserves forward/reverse direction', () {
    expect(
      mapThrottleInputToUs(
        throttle: 1,
        lowPercent: -50,
        centerPercent: -1,
        highPercent: 80,
      ),
      1250,
    );
    expect(
      mapThrottleInputToUs(
        throttle: 0,
        lowPercent: -50,
        centerPercent: -1,
        highPercent: 80,
      ),
      1495,
    );
    expect(
      mapThrottleInputToUs(
        throttle: -1,
        lowPercent: -50,
        centerPercent: -1,
        highPercent: 80,
      ),
      1900,
    );
  });
}

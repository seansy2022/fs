import 'package:controller_app/src/features/settings/models/gear_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('默认挡位比例保持当前 App 的控制行为', () {
    const settings = GearSettings.defaults;

    expect(settings.lowReversePercent, 100);
    expect(settings.lowForwardPercent, 50);
    expect(settings.highReversePercent, 100);
    expect(settings.highForwardPercent, 100);
  });

  test('旧本地设置缺少挡位配置时使用当前 App 初始值', () {
    final settings = GearSettings.fromJson(null);

    expect(settings, GearSettings.defaults);
  });

  test('按挡位和方向应用对应的控制比例', () {
    const settings = GearSettings(
      lowReversePercent: 30,
      lowForwardPercent: 50,
      highReversePercent: 60,
      highForwardPercent: 100,
    );

    expect(
      applyGearThrottleRatio(throttle: 1, highGear: false, settings: settings),
      0.5,
    );
    expect(
      applyGearThrottleRatio(throttle: -1, highGear: false, settings: settings),
      -0.3,
    );
    expect(
      applyGearThrottleRatio(throttle: 1, highGear: true, settings: settings),
      1,
    );
    expect(
      applyGearThrottleRatio(throttle: -1, highGear: true, settings: settings),
      -0.6,
    );
  });

  test('比例限制在 0% 到 100%', () {
    expect(normalizeGearPercent(-1), 0);
    expect(normalizeGearPercent(101), 100);
  });
}

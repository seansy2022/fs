import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class AppVibration {
  const AppVibration._();

  static const _alertDuration = Duration(seconds: 2);
  static const _mediumAmplitude = 128;

  /// 统一触发两秒中度报警震动；不支持振幅控制时使用系统默认强度。
  static Future<void> alert() async {
    try {
      if (await Vibration.hasVibrator()) {
        final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
        await Vibration.vibrate(
          duration: _alertDuration.inMilliseconds,
          amplitude: hasAmplitudeControl ? _mediumAmplitude : -1,
        );
        return;
      }
    } catch (_) {}
    await HapticFeedback.mediumImpact();
  }

  static Future<void> stop() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }
}

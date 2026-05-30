import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class AppVibration {
  const AppVibration._();

  static Future<void> alert({Duration duration = const Duration(milliseconds: 500)}) async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(
          duration: duration.inMilliseconds,
          amplitude: 255,
        );
        return;
      }
    } catch (_) {}
    await HapticFeedback.heavyImpact();
  }

  static Future<void> stop() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }
}

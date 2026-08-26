import 'package:controller_app/src/features/control/controllers/control_runtime_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('control input runtime restores gyro state and trims', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final store = ControlRuntimeStore();

    await store.saveInputState(
      const StoredControlInputState(
        gyroEnabled: true,
        throttleTrim: -12,
        steeringTrim: 18,
        sliderButtonsVisible: true,
      ),
    );

    final saved = await ControlRuntimeStore().loadInputState();
    expect(saved.gyroEnabled, isTrue);
    expect(saved.throttleTrim, -12);
    expect(saved.steeringTrim, 18);
    expect(saved.sliderButtonsVisible, isTrue);
  });

  test('control sound runtime restores disabled switches', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final store = ControlRuntimeStore();

    await store.saveSoundState(
      const StoredControlSoundState(
        backgroundSoundEnabled: false,
        effectSoundEnabled: false,
      ),
    );

    final saved = await ControlRuntimeStore().loadSoundState();
    expect(saved.backgroundSoundEnabled, isFalse);
    expect(saved.effectSoundEnabled, isFalse);
  });

  test('missing runtime record keeps the existing default switches', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});

    final input = await ControlRuntimeStore().loadInputState();
    final sound = await ControlRuntimeStore().loadSoundState();

    expect(input.gyroEnabled, isFalse);
    expect(input.throttleTrim, 0);
    expect(input.steeringTrim, 0);
    expect(input.sliderButtonsVisible, isFalse);
    expect(sound.backgroundSoundEnabled, isTrue);
    expect(sound.effectSoundEnabled, isTrue);
  });

  test('legacy trim is restored as steering trim', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'controller_app.control_input_runtime.v1':
          '{"gyroEnabled":true,"trim":9}',
    });

    final saved = await ControlRuntimeStore().loadInputState();

    expect(saved.gyroEnabled, isTrue);
    expect(saved.throttleTrim, 0);
    expect(saved.steeringTrim, 9);
  });

  test('restored trims stay within the new plus or minus 60 steps', () {
    final restored = StoredControlInputState.fromJson(<String, Object?>{
      'throttleTrim': 99,
      'steeringTrim': -99,
    });

    expect(restored.throttleTrim, 60);
    expect(restored.steeringTrim, -60);
  });
}

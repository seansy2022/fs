import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/features/settings/view/gyro/gyro_control_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets('单通道体感模式才允许选择体感手型', (tester) async {
    final controller = _TestSettingsController(AppSettingsState.defaults());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1216,
              height: 184,
              child: GyroControlSection(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    controller.setGyroMode(GyroMode.all);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('gyro-hand-右手')),
      warnIfMissed: false,
    );
    expect(controller.state.gyroHandMode, GyroHandMode.left);

    controller.setGyroMode(GyroMode.throttleOnly);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gyro-hand-右手')));
    await tester.pumpAndSettle();

    expect(controller.state.gyroHandMode, GyroHandMode.right);
  });
}

class _TestSettingsController extends SettingsController {
  _TestSettingsController(AppSettingsState initialState) : super() {
    state = initialState;
  }
}

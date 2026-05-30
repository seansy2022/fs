import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/features/settings/view/alarm_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets('battery conversion section renders current values', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(
            (ref) => _TestSettingsController(AppSettingsState.defaults()),
          ),
        ],
        child: const MaterialApp(home: AlarmSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('电量转换'), findsOneWidget);
    expect(find.text('2S'), findsOneWidget);
    expect(find.text('6V'), findsOneWidget);
    expect(find.text('8.4V'), findsOneWidget);
    expect(find.text('6.4V'), findsOneWidget);
    expect(find.text('15%'), findsOneWidget);
  });

  testWidgets('battery alert voice and vibration can both stay enabled', (
    tester,
  ) async {
    final controller = _TestSettingsController(
      AppSettingsState.defaults().copyWith(
        batteryVoice: false,
        batteryVibration: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: AlarmSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('语音').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('震动').first);
    await tester.pumpAndSettle();

    expect(controller.state.batteryVoice, isTrue);
    expect(controller.state.batteryVibration, isTrue);
  });

  testWidgets('signal and reconnect alerts can keep voice and vibration', (
    tester,
  ) async {
    final controller = _TestSettingsController(
      AppSettingsState.defaults().copyWith(
        signalVoice: false,
        signalVibration: false,
        reconnectVoice: false,
        reconnectVibration: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: AlarmSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('语音').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('震动').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('语音').at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('震动').at(2));
    await tester.pumpAndSettle();

    expect(controller.state.signalVoice, isTrue);
    expect(controller.state.signalVibration, isTrue);
    expect(controller.state.reconnectVoice, isTrue);
    expect(controller.state.reconnectVibration, isTrue);
  });
}

class _TestSettingsController extends SettingsController {
  _TestSettingsController(AppSettingsState initialState) : super() {
    state = initialState;
  }
}

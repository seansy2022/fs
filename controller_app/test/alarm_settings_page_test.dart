import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/core/localization/app_localizations.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/features/settings/view/alarm_settings_page.dart';
import 'package:controller_app/src/provider/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    AppText.setLanguage(AppLanguage.chinese);
  });

  testWidgets('battery settings are hidden when feature is disabled', (
    tester,
  ) async {
    _prepareSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(
            (ref) => _TestSettingsController(AppSettingsState.defaults()),
          ),
        ],
        child: _localizedApp(const AlarmSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('模型低电压报警'), findsNothing);
    expect(find.text('电量转换'), findsNothing);
    expect(find.text('模型低信号报警'), findsOneWidget);
  });

  testWidgets('battery conversion section renders current values', (
    tester,
  ) async {
    _prepareSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appFeatureFlagsProvider.overrideWithValue(
            const AppFeatureFlags(receiverBatteryEnabled: true),
          ),
          appSettingsProvider.overrideWith(
            (ref) => _TestSettingsController(AppSettingsState.defaults()),
          ),
        ],
        child: _localizedApp(const AlarmSettingsPage()),
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
    _prepareSurface(tester);
    final controller = _TestSettingsController(
      AppSettingsState.defaults().copyWith(
        batteryVoice: false,
        batteryVibration: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appFeatureFlagsProvider.overrideWithValue(
            const AppFeatureFlags(receiverBatteryEnabled: true),
          ),
          appSettingsProvider.overrideWith((ref) => controller),
        ],
        child: _localizedApp(const AlarmSettingsPage()),
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
    _prepareSurface(tester);
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
        child: _localizedApp(const AlarmSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('语音').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('震动').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('语音').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('震动').at(1));
    await tester.pumpAndSettle();

    expect(controller.state.signalVoice, isTrue);
    expect(controller.state.signalVibration, isTrue);
    expect(controller.state.reconnectVoice, isTrue);
    expect(controller.state.reconnectVibration, isTrue);
  });
}

Widget _localizedApp(Widget home) {
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

/// 使用真机横屏尺寸，避免设置页在测试默认窄窗口中产生无关溢出。
void _prepareSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _TestSettingsController extends SettingsController {
  _TestSettingsController(AppSettingsState initialState) : super() {
    state = initialState;
  }
}

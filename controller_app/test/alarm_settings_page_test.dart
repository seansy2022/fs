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
}

class _TestSettingsController extends SettingsController {
  _TestSettingsController(AppSettingsState initialState) : super() {
    state = initialState;
  }
}

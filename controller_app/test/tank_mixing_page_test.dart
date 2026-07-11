import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/features/settings/view/tank_mixing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('履带混控关闭时禁用数值输入，开启后恢复编辑', (tester) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = _TestSettingsController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: Scaffold(body: TankMixingContent())),
      ),
    );

    expect(controller.state.tankMixingEnabled, isFalse);
    expect(find.text('履带混控：'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('履带混控：')).dy,
      lessThan(tester.getTopLeft(find.text('左转')).dy),
    );
    expect(
      tester.getRect(find.byKey(tankMixingEnabledSwitchKey)).right,
      lessThanOrEqualTo(
        tester.getRect(find.byType(TankProgressTrack).first).left - 24,
      ),
    );
    final disabledInputButtons = tester
        .widgetList<RCButton>(find.byType(RCButton))
        .where((button) => button.key != tankMixingEnabledSwitchKey)
        .toList();
    expect(disabledInputButtons.first.onTap, isNull);

    await tester.tap(find.byKey(tankMixingEnabledSwitchKey));
    await tester.pump();

    expect(controller.state.tankMixingEnabled, isTrue);
    expect(find.text('开启'), findsOneWidget);
    final enabledInputButtons = tester
        .widgetList<RCButton>(find.byType(RCButton))
        .where((button) => button.key != tankMixingEnabledSwitchKey)
        .toList();
    expect(enabledInputButtons.first.onTap, isNotNull);
  });
}

class _TestSettingsController extends SettingsController {
  _TestSettingsController() : super() {
    state = AppSettingsState.defaults();
  }
}

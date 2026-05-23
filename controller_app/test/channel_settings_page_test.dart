import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/features/settings/view/channel_settings_page.dart';
import 'package:controller_app/src/features/settings/widgets/settings_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets('CH3 and CH4 render aux card fields by default', (tester) async {
    await _pumpPage(tester, AppSettingsState.defaults());

    expect(find.text('控制类型'), findsNWidgets(2));
    expect(find.text('名称'), findsNWidgets(2));
    expect(find.text('辅助1'), findsOneWidget);
    expect(find.text('辅助2'), findsOneWidget);
  });

  testWidgets('control type selector includes only four new options', (
    tester,
  ) async {
    await _pumpPage(tester, AppSettingsState.defaults());

    await tester.tap(find.text('开关').first);
    await tester.pumpAndSettle();

    expect(find.text('禁用'), findsOneWidget);
    expect(find.text('开关'), findsWidgets);
    expect(find.text('多状态'), findsOneWidget);
    expect(find.text('值'), findsOneWidget);
    expect(find.text('大灯'), findsNothing);
    expect(find.text('警示灯'), findsNothing);
    expect(find.text('挡位控制'), findsNothing);
    expect(find.text('陀螺仪'), findsNothing);
  });

  testWidgets('disabled type hides config area', (tester) async {
    await _pumpPage(
      tester,
      _stateWithAux(
        ch3Type: AuxControlType.disabled,
        ch4Type: AuxControlType.switchControl,
      ),
    );

    final card = _auxCardFor('辅助1');
    expect(find.descendant(of: card, matching: find.text('开')), findsNothing);
    expect(find.descendant(of: card, matching: find.text('关')), findsNothing);
    expect(find.descendant(of: card, matching: find.text('设置值')), findsNothing);
    expect(find.descendant(of: card, matching: find.text('新增')), findsNothing);
  });

  testWidgets('switch type shows on and off editors', (tester) async {
    await _pumpPage(
      tester,
      _stateWithAux(
        ch3Type: AuxControlType.switchControl,
        ch4Type: AuxControlType.disabled,
      ),
    );

    final card = _auxCardFor('辅助1');
    expect(find.descendant(of: card, matching: find.text('开')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('关')), findsOneWidget);
  });

  testWidgets('multi state shows default values and can add one', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      _stateWithAux(
        ch3Type: AuxControlType.multiState,
        ch4Type: AuxControlType.disabled,
      ),
    );

    final card = _auxCardFor('辅助1');
    expect(
      find.descendant(of: card, matching: find.text('状态1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('状态2')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('状态3')),
      findsOneWidget,
    );

    await tester.tap(find.descendant(of: card, matching: find.text('新增')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: card, matching: find.text('状态4')),
      findsOneWidget,
    );
  });

  testWidgets('value type shows single value editor', (tester) async {
    await _pumpPage(
      tester,
      _stateWithAux(
        ch3Type: AuxControlType.value,
        ch4Type: AuxControlType.disabled,
      ),
    );

    final card = _auxCardFor('辅助1');
    expect(
      find.descendant(of: card, matching: find.text('设置值')),
      findsOneWidget,
    );
    expect(find.descendant(of: card, matching: find.text('开')), findsNothing);
    expect(find.descendant(of: card, matching: find.text('状态1')), findsNothing);
  });

  testWidgets('editing name persists after rebuild', (tester) async {
    final controller = _TestSettingsController(AppSettingsState.defaults());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: ChannelSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    final textField = find.byType(TextField).first;
    await tester.enterText(textField, '机械臂');
    await tester.pumpAndSettle();

    expect(controller.state.channels[2].displayName, '机械臂');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: ChannelSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('机械臂'), findsOneWidget);
  });
}

Future<void> _pumpPage(WidgetTester tester, AppSettingsState state) async {
  final controller = _TestSettingsController(state);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appSettingsProvider.overrideWith((ref) => controller)],
      child: const MaterialApp(home: ChannelSettingsPage()),
    ),
  );

  await tester.pumpAndSettle();
}

AppSettingsState _stateWithAux({
  required AuxControlType ch3Type,
  required AuxControlType ch4Type,
}) {
  final defaults = AppSettingsState.defaults();
  final channels = defaults.channels.toList(growable: true);
  channels[2] = channels[2].copyWith(controlType: ch3Type);
  channels[3] = channels[3].copyWith(controlType: ch4Type);
  return defaults.copyWith(channels: channels);
}

Finder _auxCardFor(String name) {
  return find.ancestor(
    of: find.text(name),
    matching: find.byType(SettingsStrip),
  );
}

class _TestSettingsController extends SettingsController {
  _TestSettingsController(AppSettingsState initialState) : super() {
    state = initialState;
  }
}

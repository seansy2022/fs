import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/core/localization/app_localizations.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/features/settings/view/channel_settings_page.dart';
import 'package:controller_app/src/features/settings/widgets/settings_workspace.dart';
import 'package:controller_app/src/provider/app_locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';
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

  testWidgets('切换语言时通道设置无需重新进入页面', (tester) async {
    final localeController = AppLocaleController();
    await localeController.setLanguage(AppLanguage.english);
    final settingsController = _TestSettingsController(
      AppSettingsState.defaults(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith((ref) => settingsController),
          appLocaleProvider.overrideWith((ref) => localeController),
        ],
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChannelSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Steering (CH1)'), findsOneWidget);

    await localeController.setLanguage(AppLanguage.chinese);
    await tester.pump();

    expect(find.text('方向(CH1)'), findsOneWidget);
    expect(find.text('Steering (CH1)'), findsNothing);
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

  testWidgets('selecting multi state starts with three default values', (
    tester,
  ) async {
    await _pumpPage(tester, AppSettingsState.defaults());

    await tester.tap(find.text('开关').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('多状态'));
    await tester.pumpAndSettle();

    final card = _auxCardFor('辅助1');
    expect(
      find.descendant(of: card, matching: find.text('-100%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('0%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('100%')),
      findsOneWidget,
    );
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
      find.descendant(of: card, matching: find.text('状态 1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('状态 2')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('状态 3')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('-100%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('0%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('100%')),
      findsOneWidget,
    );

    await tester.tap(find.descendant(of: card, matching: find.text('新增')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: card, matching: find.text('自定义名称')),
      findsOneWidget,
    );
  });

  testWidgets('multi state keeps at most five items', (tester) async {
    await _pumpPage(
      tester,
      _stateWithAux(
        ch3Type: AuxControlType.multiState,
        ch4Type: AuxControlType.disabled,
      ),
    );

    final card = _auxCardFor('辅助1');
    await tester.tap(find.descendant(of: card, matching: find.text('新增')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: card, matching: find.text('新增')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.text('自定义名称')),
      findsNWidgets(2),
    );
    expect(find.descendant(of: card, matching: find.text('新增')), findsNothing);
  });

  testWidgets('multi state label can be edited and falls back when cleared', (
    tester,
  ) async {
    final controller = _TestSettingsController(
      _stateWithAux(
        ch3Type: AuxControlType.multiState,
        ch4Type: AuxControlType.disabled,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: ChannelSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    final card = _auxCardFor('辅助1');
    await tester.tap(
      find
          .descendant(
            of: card,
            matching: find.byKey(
              const ValueKey<String>('multi-state-label-edit'),
            ),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('修改状态名称'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '低速');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(controller.state.channels[2].multiStateLabels.first, '低速');

    await tester.tap(
      find
          .descendant(
            of: card,
            matching: find.byKey(
              const ValueKey<String>('multi-state-label-edit'),
            ),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(controller.state.channels[2].multiStateLabels.first, '状态 1');
  });

  testWidgets('aux value editor allows extended signed range', (tester) async {
    final controller = _TestSettingsController(
      _stateWithAux(
        ch3Type: AuxControlType.value,
        ch4Type: AuxControlType.disabled,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: ChannelSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    final card = _auxCardFor('辅助1');
    await tester.tap(find.descendant(of: card, matching: find.text('0%')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '120');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.state.channels[2].singleValue, 120);
    expect(
      find.descendant(of: card, matching: find.text('120%')),
      findsOneWidget,
    );
  });

  testWidgets(
    'multi state delete button appears beside add above three items',
    (tester) async {
      await _pumpPage(
        tester,
        _stateWithAux(
          ch3Type: AuxControlType.multiState,
          ch4Type: AuxControlType.disabled,
        ),
      );

      final card = _auxCardFor('辅助1');
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(
            const ValueKey<String>('multi-state-delete-icon'),
          ),
        ),
        findsNothing,
      );

      await tester.tap(find.descendant(of: card, matching: find.text('新增')));
      await tester.pumpAndSettle();

      final deleteFinder = find.descendant(
        of: card,
        matching: find.byKey(const ValueKey<String>('multi-state-delete-icon')),
      );
      expect(deleteFinder, findsOneWidget);

      await tester.tap(deleteFinder);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: card, matching: find.text('自定义名称')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(
            const ValueKey<String>('multi-state-delete-icon'),
          ),
        ),
        findsNothing,
      );
    },
  );

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
    expect(
      find.descendant(of: card, matching: find.text('状态 1')),
      findsNothing,
    );
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

  testWidgets('CH1 and CH2 value buttons use 60 width', (tester) async {
    await _pumpPage(tester, AppSettingsState.defaults());

    final buttons = tester.widgetList<RCButton>(find.byType(RCButton)).toList();

    expect(buttons.length, greaterThanOrEqualTo(6));
    for (final button in buttons.take(6)) {
      expect(button.width, 60);
    }
  });

  testWidgets('CH1 low button opens editor and updates value', (tester) async {
    final controller = _TestSettingsController(AppSettingsState.defaults());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: ChannelSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('-100%').first);
    await tester.pumpAndSettle();

    expect(find.text('设置CH1低'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      '100',
    );

    await tester.enterText(find.byType(TextField).last, '80');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.state.channels.first.lowPercent, -80);
    expect(find.text('-80%'), findsOneWidget);
  });

  testWidgets('CH1 low editor submits magnitude as negative value', (
    tester,
  ) async {
    final defaults = AppSettingsState.defaults();
    final channels = defaults.channels.toList(growable: true);
    channels[0] = channels[0].copyWith(lowPercent: 0);
    final controller = _TestSettingsController(
      defaults.copyWith(channels: channels),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: ChannelSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('0%').first);
    await tester.pumpAndSettle();

    expect(find.text('设置CH1低'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '50');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.state.channels.first.lowPercent, -50);
    expect(find.text('-50%'), findsOneWidget);
  });

  testWidgets('CH1 high editor blocks negative input', (tester) async {
    final defaults = AppSettingsState.defaults();
    final channels = defaults.channels.toList(growable: true);
    channels[0] = channels[0].copyWith(highPercent: 0);
    final controller = _TestSettingsController(
      defaults.copyWith(channels: channels),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: ChannelSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('0%').first);
    await tester.pumpAndSettle();

    expect(find.text('设置CH1高'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '-50');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.state.channels.first.highPercent, 50);
    expect(find.text('-50%'), findsNothing);
  });

  testWidgets('CH1 high editor blocks values above 100', (tester) async {
    final defaults = AppSettingsState.defaults();
    final channels = defaults.channels.toList(growable: true);
    channels[0] = channels[0].copyWith(highPercent: 99);
    final controller = _TestSettingsController(
      defaults.copyWith(channels: channels),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: ChannelSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('99%').first);
    await tester.pumpAndSettle();

    expect(find.text('设置CH1高'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '9999');
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      '99',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.state.channels.first.highPercent, 99);
    expect(find.text('9999%'), findsNothing);
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

import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/features/settings/pages/channel_settings_page.dart';
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

  testWidgets('CH3 headlight shows off and on fields', (tester) async {
    await _pumpPage(
      tester,
      _stateWithChannels(
        ch3Function: AuxiliaryFunction.headlight,
        ch4Function: AuxiliaryFunction.none,
      ),
    );

    final row = _rowFor('大灯(CH3)');
    expect(find.descendant(of: row, matching: find.text('关')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('开')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('空')), findsNothing);
    expect(find.descendant(of: row, matching: find.text('调置位')), findsNothing);
    expect(find.descendant(of: row, matching: find.text('反向')), findsNothing);
  });

  testWidgets('CH4 warning light shows off and on fields', (tester) async {
    await _pumpPage(
      tester,
      _stateWithChannels(
        ch3Function: AuxiliaryFunction.none,
        ch4Function: AuxiliaryFunction.warningLight,
      ),
    );

    final row = _rowFor('警示灯(CH4)');
    expect(find.descendant(of: row, matching: find.text('关')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('开')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('空')), findsNothing);
    expect(find.descendant(of: row, matching: find.text('调置位')), findsNothing);
    expect(find.descendant(of: row, matching: find.text('反向')), findsNothing);
  });

  testWidgets('CH4 gear control shows low high and neutral fields', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      _stateWithChannels(
        ch3Function: AuxiliaryFunction.none,
        ch4Function: AuxiliaryFunction.gearControl,
      ),
    );

    final row = _rowFor('挡位控制(CH4)');
    expect(find.descendant(of: row, matching: find.text('低')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('高')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('空')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('调置位')), findsNothing);
  });

  testWidgets('CH3 gyro shows an editable input field', (tester) async {
    await _pumpPage(
      tester,
      _stateWithChannels(
        ch3Function: AuxiliaryFunction.gyro,
        ch4Function: AuxiliaryFunction.none,
      ),
    );

    final row = _rowFor('陀螺仪(CH3)');
    expect(
      find.descendant(of: row, matching: find.text('设置值')),
      findsOneWidget,
    );
    expect(find.descendant(of: row, matching: find.text('关')), findsNothing);
    expect(find.descendant(of: row, matching: find.text('开')), findsNothing);
    expect(find.descendant(of: row, matching: find.text('空')), findsNothing);

    await tester.tap(find.descendant(of: row, matching: find.text('0%')));
    await tester.pumpAndSettle();

    expect(find.text('设置值'), findsNWidgets(2));
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '25');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: row, matching: find.text('25%')),
      findsOneWidget,
    );
  });

  testWidgets('CH4 selector excludes removed light functions', (tester) async {
    await _pumpPage(
      tester,
      _stateWithChannels(
        ch3Function: AuxiliaryFunction.none,
        ch4Function: AuxiliaryFunction.none,
      ),
    );

    await tester.tap(find.byIcon(Icons.chevron_right).last);
    await tester.pumpAndSettle();

    expect(find.text('无'), findsOneWidget);
    expect(find.text('大灯'), findsOneWidget);
    expect(find.text('警示灯'), findsOneWidget);
    expect(find.text('挡位控制'), findsOneWidget);
    expect(find.text('陀螺仪'), findsOneWidget);
    expect(find.text('刹车灯'), findsNothing);
    expect(find.text('倒车灯'), findsNothing);
    expect(find.text('左转灯'), findsNothing);
    expect(find.text('右转灯'), findsNothing);
  });

  testWidgets('CH4 function cell opens selector dialog', (tester) async {
    await _pumpPage(
      tester,
      _stateWithChannels(
        ch3Function: AuxiliaryFunction.none,
        ch4Function: AuxiliaryFunction.none,
      ),
    );

    await tester.tap(find.text('无(CH4)'));
    await tester.pumpAndSettle();

    expect(find.text('选择辅助功能'), findsOneWidget);
    expect(find.text('挡位控制'), findsOneWidget);
  });

  testWidgets('configured CH3 function cell opens selector dialog', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      _stateWithChannels(
        ch3Function: AuxiliaryFunction.headlight,
        ch4Function: AuxiliaryFunction.none,
      ),
    );

    await tester.tap(find.text('大灯(CH3)'));
    await tester.pumpAndSettle();

    expect(find.text('选择辅助功能'), findsOneWidget);
    expect(find.text('警示灯'), findsOneWidget);
  });

  testWidgets('none state shows function label with channel suffix', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      _stateWithChannels(
        ch3Function: AuxiliaryFunction.none,
        ch4Function: AuxiliaryFunction.none,
      ),
    );

    expect(find.text('无(CH3)'), findsOneWidget);
    expect(find.text('无(CH4)'), findsOneWidget);
  });

  testWidgets('CH3 and CH4 function options are mutually exclusive', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      _stateWithChannels(
        ch3Function: AuxiliaryFunction.headlight,
        ch4Function: AuxiliaryFunction.none,
      ),
    );

    await tester.tap(find.byIcon(Icons.chevron_right).last);
    await tester.pumpAndSettle();

    expect(find.text('大灯'), findsNothing);
    expect(find.text('警示灯'), findsOneWidget);
    expect(find.text('挡位控制'), findsOneWidget);
    expect(find.text('陀螺仪'), findsOneWidget);
  });

  testWidgets('gyro row title stays on one line', (tester) async {
    await _pumpPage(
      tester,
      _stateWithChannels(
        ch3Function: AuxiliaryFunction.gyro,
        ch4Function: AuxiliaryFunction.none,
      ),
    );

    final title = tester.widget<Text>(find.text('陀螺仪(CH3)'));
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
  });

  testWidgets('gyro field label stays on one line', (tester) async {
    await _pumpPage(
      tester,
      _stateWithChannels(
        ch3Function: AuxiliaryFunction.gyro,
        ch4Function: AuxiliaryFunction.none,
      ),
    );

    final label = tester.widget<Text>(
      find
          .descendant(of: _rowFor('陀螺仪(CH3)'), matching: find.text('设置值'))
          .first,
    );
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
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

AppSettingsState _stateWithChannels({
  required AuxiliaryFunction ch3Function,
  required AuxiliaryFunction ch4Function,
}) {
  final defaults = AppSettingsState.defaults();
  final channels = defaults.channels.toList(growable: true);
  channels[2] = channels[2].copyWith(function: ch3Function);
  channels[3] = channels[3].copyWith(function: ch4Function);
  return defaults.copyWith(channels: channels);
}

Finder _rowFor(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byType(SettingsStrip),
  );
}

class _TestSettingsController extends SettingsController {
  _TestSettingsController(AppSettingsState initialState) : super() {
    state = initialState;
  }
}

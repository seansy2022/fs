import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/settings/controllers/settings_controller.dart';
import 'package:controller_app/src/features/settings/models/app_settings_state.dart';
import 'package:controller_app/src/features/settings/pages/settings_page.dart';
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

  testWidgets('gyro mode buttons are 74 by 28 with lowercase all', (
    tester,
  ) async {
    final controller = _TestSettingsController(
      AppSettingsState.defaults().copyWith(gyroMode: GyroMode.all),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: Scaffold(body: BasicSettingsContent())),
      ),
    );
    await tester.pumpAndSettle();

    final toggle = tester.widget<RcMultiToggle<String>>(
      find.byType(RcMultiToggle<String>),
    );
    expect(toggle.width, 222);
    expect(toggle.height, 28);

    expect(find.text('all'), findsOneWidget);
    expect(find.text('ALL'), findsNothing);

    final allText = tester.widget<Text>(find.text('all'));
    expect(allText.style?.fontWeight, AppFonts.w400);
  });

  testWidgets('default background music label sits next to arrow', (
    tester,
  ) async {
    final controller = _TestSettingsController(AppSettingsState.defaults());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: Scaffold(body: BasicSettingsContent())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('默认'), findsOneWidget);
    expect(find.text('默认背景音乐'), findsNothing);

    final labelRect = tester.getRect(find.text('默认'));
    final arrowRect = tester.getRect(find.byIcon(Icons.chevron_right).last);
    expect(arrowRect.left - labelRect.right, closeTo(8, 0.1));
  });

  testWidgets('background music dialog matches bluetooth-style options', (
    tester,
  ) async {
    final controller = _TestSettingsController(
      AppSettingsState.defaults().copyWith(
        backgroundMusicMode: BackgroundMusicMode.localTrack,
        backgroundMusicName: 'song.mp3',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: Scaffold(body: BasicSettingsContent())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('背景音乐').first);
    await tester.pumpAndSettle();

    expect(find.text('背景音乐'), findsNWidgets(2));
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    expect(find.text('默认背景音乐'), findsOneWidget);
    expect(find.text('选择本地音乐'), findsOneWidget);
    expect(find.byKey(const ValueKey('bg-music-check-选择本地音乐')), findsOneWidget);
    expect(find.byKey(const ValueKey('bg-music-check-默认背景音乐')), findsNothing);

    final titleRect = tester.getRect(find.text('背景音乐').last);
    final closeRect = tester.getRect(find.byIcon(Icons.cancel_outlined));
    expect(titleRect.left, lessThan(closeRect.left));

    await tester.tap(find.text('默认背景音乐'));
    await tester.pumpAndSettle();

    expect(
      controller.state.backgroundMusicMode,
      BackgroundMusicMode.defaultTrack,
    );
    expect(controller.state.backgroundMusicName, '默认');
    expect(find.text('默认背景音乐'), findsNothing);
  });

  testWidgets('background music dialog shows check on default option', (
    tester,
  ) async {
    final controller = _TestSettingsController(AppSettingsState.defaults());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: Scaffold(body: BasicSettingsContent())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('背景音乐').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bg-music-check-默认背景音乐')), findsOneWidget);
    expect(find.byKey(const ValueKey('bg-music-check-选择本地音乐')), findsNothing);
  });
}

class _TestSettingsController extends SettingsController {
  _TestSettingsController(AppSettingsState initialState) : super() {
    state = initialState;
  }
}

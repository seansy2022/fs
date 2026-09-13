import 'package:controller_app/src/core/localization/app_localizations.dart';
import 'package:controller_app/src/core/providers.dart';
import 'package:controller_app/src/features/settings/view/settings_page.dart';
import 'package:controller_app/src/provider/app_locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/home_page_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'controller_app.locale.v1': 'zh',
    });
    AppText.setLanguage(AppLanguage.chinese);
  });

  testWidgets('设置页切换英文后子页立即刷新，无需返回首页', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final localeController = AppLocaleController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLocaleProvider.overrideWith((ref) => localeController),
          receiverRepositoryProvider.overrideWith(
            (ref) => _SettingsReceiverRepository(),
          ),
        ],
        child: const _LocaleAwareSettingsApp(),
      ),
    );
    await _pumpUi(tester);

    await tester.ensureVisible(find.text('语言'));
    await tester.tap(find.text('语言'));
    await _pumpUi(tester);
    await tester.tap(find.text('English'));
    await _pumpUi(tester);

    expect(find.text('Channels'), findsOneWidget);
    await tester.tap(find.text('Channels'));
    await _pumpUi(tester);
    expect(find.text('Steering (CH1)'), findsOneWidget);
    expect(find.text('Control Type'), findsNWidgets(2));

    await tester.tap(find.text('Fail-safe'));
    await _pumpUi(tester);
    expect(find.text('Steering'), findsOneWidget);
    expect(find.text('Throttle'), findsOneWidget);
    expect(find.text('Hold'), findsNWidgets(4));
    expect(find.text('方向'), findsNothing);
  });
}

/// 推进弹窗与页面切换动画；设置背景有常驻动画，不能使用 pumpAndSettle。
Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _LocaleAwareSettingsApp extends ConsumerWidget {
  const _LocaleAwareSettingsApp();

  @override
  /// 跟随语言 Provider 更新 MaterialApp 的本地化上下文。
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLocaleProvider);
    return MaterialApp(
      locale: language.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsPage(),
    );
  }
}

class _SettingsReceiverRepository extends FakeHomeReceiverRepository {
  _SettingsReceiverRepository()
    : super(connectionState: ReceiverConnectionState.disconnected);

  @override
  Stream<ReceiverFirmwareInfo?> get firmwareInfoStream => Stream.value(null);
}

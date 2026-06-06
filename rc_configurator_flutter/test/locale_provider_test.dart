import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rc_configurator_flutter/l10n/app_localizations.dart';
import 'package:rc_configurator_flutter/src/page/home/enter.dart';
import 'package:rc_configurator_flutter/src/provider/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('resolveInitialLocale returns saved zh locale', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'zh'});
    final locale = await resolveInitialLocale(systemLocale: const Locale('en'));
    expect(locale.languageCode, 'zh');
  });

  test('resolveInitialLocale returns saved en locale', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final locale = await resolveInitialLocale(systemLocale: const Locale('zh'));
    expect(locale.languageCode, 'en');
  });

  test('resolveInitialLocale stores zh on first launch', () async {
    final locale = await resolveInitialLocale(
      systemLocale: const Locale('zh', 'CN'),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(locale.languageCode, 'zh');
    expect(prefs.getString('app_locale'), 'zh');
  });

  test('resolveInitialLocale stores en for non-zh locale', () async {
    final locale = await resolveInitialLocale(
      systemLocale: const Locale('fr', 'FR'),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(locale.languageCode, 'en');
    expect(prefs.getString('app_locale'), 'en');
  });

  test('setLocale updates state and shared preferences', () async {
    final container = ProviderContainer(
      overrides: [initialLocaleProvider.overrideWithValue(const Locale('en'))],
    );
    addTearDown(container.dispose);
    await container.read(localeProvider.notifier).setLocale(const Locale('zh'));
    final prefs = await SharedPreferences.getInstance();
    expect(container.read(localeProvider).languageCode, 'zh');
    expect(prefs.getString('app_locale'), 'zh');
  });

  testWidgets('EnterPage uses injected locale on first frame', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocaleProvider.overrideWithValue(const Locale('zh')),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            return MaterialApp(
              locale: ref.watch(localeProvider),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const EnterPage(),
            );
          },
        ),
      ),
    );
    expect(find.text('MG11 Assistant'), findsNothing);
  });
}

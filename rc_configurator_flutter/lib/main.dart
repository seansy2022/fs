import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';
import 'src/provider/locale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final locale = await resolveInitialLocale(
    systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF001024),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await FlutterBluePlus.setLogLevel(LogLevel.none);
  runApp(
    ProviderScope(
      overrides: [initialLocaleProvider.overrideWithValue(locale)],
      child: const RcConfiguratorApp(),
    ),
  );
}

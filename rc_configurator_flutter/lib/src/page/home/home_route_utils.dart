import 'package:flutter/widgets.dart';
import 'package:rc_configurator_flutter/l10n/app_localizations.dart';
import '../../types.dart';

bool isHomeScreen(Screen screen) => _homeScreens.contains(screen);

Screen homeScreen(Screen screen) =>
    isHomeScreen(screen) ? screen : Screen.dashboard;

String homeTitleFor(Screen screen, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return switch (screen) {
    Screen.functions => l10n.homeMenu,
    Screen.bluetooth => l10n.homeAvailableDevices,
    _ => l10n.appTitle,
  };
}

const _homeScreens = <Screen>{
  Screen.dashboard,
  Screen.functions,
  Screen.bluetooth,
};

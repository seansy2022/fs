import '../../types.dart';

bool isHomeScreen(Screen screen) => _homeScreens.contains(screen);

Screen homeScreen(Screen screen) =>
    isHomeScreen(screen) ? screen : Screen.dashboard;

String homeTitleFor(Screen screen) => switch (screen) {
  Screen.functions => '菜单',
  Screen.bluetooth => '可用设备',
  _ => 'MG11助手',
};

const _homeScreens = <Screen>{
  Screen.dashboard,
  Screen.functions,
  Screen.bluetooth,
};

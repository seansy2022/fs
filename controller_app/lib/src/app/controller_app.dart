import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../provider/battery_alert_provider.dart';
import '../provider/reconnect_alert_provider.dart';
import '../provider/signal_alert_provider.dart';
import '../features/bluetooth/view/device_list_page.dart';
import '../features/bluetooth/view/pair_receiver_page.dart';
import '../features/control/view/control_page.dart';
import '../features/help/view/help_center_page.dart';
import '../features/home/view/home_page.dart';
import '../features/settings/view/settings_page.dart';
import '../features/startup/view/startup_page.dart';
import 'app_routes.dart';

class ControllerApp extends ConsumerWidget {
  const ControllerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(batteryAlertMonitorProvider);
    ref.watch(signalAlertMonitorProvider);
    ref.watch(reconnectAlertMonitorProvider);
    return MaterialApp(
      title: 'Flysky Smart Car',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return _page(const StartupPage(), settings);
          case AppRoutes.home:
            return _page(const HomePage(), settings);
          case AppRoutes.deviceList:
            return _page(const DeviceListPage(), settings);
          case AppRoutes.pairing:
            return _page(const PairReceiverPage(), settings);
          case AppRoutes.control:
            return _page(const ControlPage(), settings);
          case AppRoutes.settings:
            return _pageNoTransition(
              const SettingsPage(initialRoute: AppRoutes.settings),
              settings,
            );
          case AppRoutes.channelSettings:
            return _pageNoTransition(
              const SettingsPage(initialRoute: AppRoutes.channelSettings),
              settings,
            );
          case AppRoutes.failsafe:
            return _pageNoTransition(
              const SettingsPage(initialRoute: AppRoutes.failsafe),
              settings,
            );
          case AppRoutes.tankMixing:
            return _pageNoTransition(
              const SettingsPage(initialRoute: AppRoutes.tankMixing),
              settings,
            );
          case AppRoutes.alarms:
            return _pageNoTransition(
              const SettingsPage(initialRoute: AppRoutes.alarms),
              settings,
            );
          case AppRoutes.firmware:
            return _pageNoTransition(
              const SettingsPage(initialRoute: AppRoutes.firmware),
              settings,
            );
          case AppRoutes.help:
            return _page(const HelpCenterPage(), settings);
          default:
            return _page(const HomePage(), settings);
        }
      },
    );
  }

  MaterialPageRoute<void> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute<void>(builder: (_) => child, settings: settings);
  }

  PageRouteBuilder<void> _pageNoTransition(
    Widget child,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => child,
    );
  }
}

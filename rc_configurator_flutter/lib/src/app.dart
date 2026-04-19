import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rc_ui/rc_ui.dart';
import 'page/home/enter.dart';
import 'page/home/home_route_page.dart';
import 'page/home/home_route_utils.dart';
import 'page/secondary/secondary_route_page.dart';
import 'page/startup_permission.dart';
import 'provider/startup_provider.dart';
import 'types.dart';

const kDebugHoldStartupScreen = false;

class AppRoutes {
  static const enter = '/enter';
  static const home = '/home';
  static const secondary = '/secondary';
}

class RcConfiguratorApp extends ConsumerWidget {
  const RcConfiguratorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      initialRoute: AppRoutes.enter,
      routes: {
        AppRoutes.enter: (_) => const _EnterRouteGate(),
        AppRoutes.home: (_) => const Scaffold(
          body: HomeRoutePage(
            secondaryRouteName: AppRoutes.secondary,
            onRequestPermissions: requestStartupPermissions,
          ),
        ),
      },
      onGenerateRoute: (settings) {
        if (settings.name != AppRoutes.secondary) return null;
        final screen = settings.arguments;
        if (screen is! Screen || isHomeScreen(screen)) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: HomeRoutePage(
                secondaryRouteName: AppRoutes.secondary,
                onRequestPermissions: requestStartupPermissions,
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: SecondaryRoutePage(screen: screen)),
        );
      },
    );
  }
}

class _EnterRouteGate extends ConsumerStatefulWidget {
  const _EnterRouteGate();

  @override
  ConsumerState<_EnterRouteGate> createState() => _EnterRouteGateState();
}

class _EnterRouteGateState extends ConsumerState<_EnterRouteGate> {
  static const _fadeOutDuration = Duration(milliseconds: 450);
  bool _isFading = false;
  bool _navigated = false;

  void _fadeOutAndNavigate() {
    if (_isFading || _navigated) return;
    setState(() => _isFading = true);
    Future<void>.delayed(_fadeOutDuration, () {
      if (!mounted || _navigated) return;
      _navigated = true;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugHoldStartupScreen) return const EnterPage();
    final startup = ref.watch(startupProvider);
    if (!startup.isReady) {
      ref.read(startupProvider.notifier).initialize();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fadeOutAndNavigate();
      });
    }
    return AnimatedOpacity(
      duration: _fadeOutDuration,
      curve: Curves.easeOut,
      opacity: _isFading ? 0.8 : 1,
      child: const EnterPage(),
    );
  }
}

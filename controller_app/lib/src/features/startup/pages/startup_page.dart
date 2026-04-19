import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';

class StartupPage extends ConsumerStatefulWidget {
  const StartupPage({super.key});

  @override
  ConsumerState<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends ConsumerState<StartupPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    try {
      await ref.read(receiverRepositoryProvider).startScan();
    } catch (error) {
      // Desktop/macOS may not expose BLE adapter in debug environment.
      debugPrint('startup scan skipped: $error');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TechShell(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0xFF062048), AppColors.bg],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SvgPicture.asset(
                AppAssets.startupTop,
                fit: BoxFit.fitWidth,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SvgPicture.asset(
                AppAssets.startupBottom,
                fit: BoxFit.fitWidth,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppAssets.startupBottomIcon,
                    width: 88,
                    height: 88,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Flysky-Smart Car',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      fontWeight: AppFonts.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '富斯智能遥控车',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: AppFonts.s14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBright,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

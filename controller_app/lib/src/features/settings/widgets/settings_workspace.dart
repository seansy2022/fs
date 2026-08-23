import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/localization/app_localizations.dart';

class SettingsWorkspace extends StatelessWidget {
  const SettingsWorkspace({
    super.key,
    required this.activeRoute,
    required this.content,
    this.onBack,
    this.onMenuSelected,
  });

  final String activeRoute;
  final Widget content;
  final VoidCallback? onBack;
  final ValueChanged<String>? onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TechShell(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr('设置'),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: AppFonts.s20,
                        fontWeight: AppFonts.w600,
                      ),
                    ),
                    const Spacer(),
                    _SettingsStartButton(onTap: () => _goToControl(context)),
                    const SizedBox(width: 16),
                    if (onBack != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onBack,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: SvgPicture.string(
                              _backIconSvg,
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 2,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0, 0.3334, 0.5092, 0.678, 1],
                      colors: [
                        Color.fromRGBO(126, 162, 207, 1),
                        Color.fromRGBO(0, 198, 255, 1),
                        Color.fromRGBO(146, 254, 157, 1),
                        Color.fromRGBO(0, 200, 255, 1),
                        Color.fromRGBO(125, 162, 206, 1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const menuWidth = 112.0;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: menuWidth,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: _menus.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final menu = _menus[index];
                                return MenuItemWidget(
                                  title: context.tr(menu.label),
                                  width: menuWidth,
                                  height: 44,
                                  selected: menu.route == activeRoute,
                                  onTap: () => _go(context, menu.route),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(child: content),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    if (route == activeRoute) {
      return;
    }
    if (onMenuSelected != null) {
      onMenuSelected!(route);
      return;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  /// 进入控制页，并移除开始页之后的中间路由。
  void _goToControl(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.control,
      ModalRoute.withName(AppRoutes.home),
    );
  }
}

const _backIconSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="48" height="48" viewBox="0 0 48 48" fill="none"><path stroke="rgba(237, 245, 255, 1)" stroke-width="4" stroke-linecap="round" d="M11.1973 36.8027L36.8027 11.1973"></path><path stroke="rgba(237, 245, 255, 1)" stroke-width="4" stroke-linecap="round" d="M36.9997 37.0002L11 11.0005"></path></svg>';

class _SettingsStartButton extends StatelessWidget {
  const _SettingsStartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 96,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryBright, AppColors.primary],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/home_start.svg',
              width: 16,
              height: 14,
            ),
            const SizedBox(width: 6),
            Text(
              context.tr('开始'),
              style: const TextStyle(
                color: AppColors.bg,
                fontSize: 14,
                fontWeight: AppFonts.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsStrip extends StatelessWidget {
  const SettingsStrip({
    super.key,
    required this.child,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final Widget child;
  final double? height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest.withValues(alpha: 0.42),
      ),
      child: child,
    );

    if (height == null) {
      return box;
    }

    return SizedBox(height: height, child: box);
  }
}

const _menus = <({String label, String route})>[
  (label: '基本设置', route: AppRoutes.settings),
  (label: '通道设置', route: AppRoutes.channelSettings),
  (label: '挡位设置', route: AppRoutes.gearSettings),
  (label: '失控保护', route: AppRoutes.failsafe),
  (label: '履带混控', route: AppRoutes.tankMixing),
  (label: '报警提示', route: AppRoutes.alarms),
  (label: '固件升级', route: AppRoutes.firmware),
  (label: '帮助中心', route: AppRoutes.help),
];

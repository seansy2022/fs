import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';

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
                    SizedBox(
                      width: 37,
                      height: 26,
                      child: SvgPicture.string(
                        _settingsTitleSvg,
                        width: 37,
                        height: 26,
                      ),
                    ),
                    const Spacer(),
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
                                  title: menu.label,
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
}

const _settingsTitleSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="71.280029296875" height="28.080078125" viewBox="0 0 71.280029296875 28.080078125" fill="none"><g><path fill="#EDF5FF" d="M15.84 22.6L10.72 18.24L11 16.32L17.48 16.32L20.88 19.32L24.92 16.68L25.08 15.52L11.12 15.52L11.64 11.8L31.88 11.8L30.88 19.04L24.84 22.76L31 28.08L22.28 28.08L19.72 25.92L16.16 28.08L7.48003 28.08L15.84 22.6ZM24.52 10.76L25.48 3.79997L20 3.79997L18.52 10.76L11.88 10.76L13.84 1.47997L12.6 0.0399723L32.24 0.0399723L31.32 6.75997L32.04 6.75997L33.36 5.23997L32.6 10.76L24.52 10.76ZM2.92063e-05 27.36L2.36003 10.68L2.92063e-05 10.68L0.520029 6.87997L9.56003 6.87997L7.48003 21.84L10.44 21.04L9.88003 25L2.92063e-05 27.36ZM8.68003 0.0399723L9.84003 5.35997L3.72003 5.35997L2.56003 0.0399723L8.68003 0.0399723ZM51.72 7.63997L52.2 6.47997L40.16 6.47997L40.96 0.839972L40.16 -2.86102e-05L71.28 -2.86102e-05L70.36 6.47997L58.2 6.47997L57.8 7.63997L71 7.63997L70.6 10.68L56.72 10.68L56.32 11.76L68.16 11.76L66.32 24.64L69.4 24.64L69 27.4L35.64 27.4L36.04 24.64L38.24 24.64L40.04 11.76L50.12 11.76L50.52 10.68L38.72 10.68L39.12 7.63997L51.72 7.63997ZM46.32 15.56L60.72 15.56L60.84 14.8L46.44 14.8L46.32 15.56ZM45.48 21.6L59.88 21.6L59.96 20.88L45.6 20.88L45.48 21.6ZM45.08 24.64L59.44 24.64L59.52 23.92L45.16 23.92L45.08 24.64ZM45.92 18.56L60.28 18.56L60.4 17.88L46 17.88L45.92 18.56ZM61.84 2.35997L61.6 4.15997L63.92 4.15997L64.16 2.35997L61.84 2.35997ZM49.56 4.15997L49.8 2.35997L47.56 2.35997L47.32 4.15997L49.56 4.15997ZM54.4 4.15997L56.64 4.15997L56.88 2.35997L54.64 2.35997L54.4 4.15997Z"></path></g></svg>';

const _backIconSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="48" height="48" viewBox="0 0 48 48" fill="none"><path stroke="rgba(237, 245, 255, 1)" stroke-width="4" stroke-linecap="round" d="M11.1973 36.8027L36.8027 11.1973"></path><path stroke="rgba(237, 245, 255, 1)" stroke-width="4" stroke-linecap="round" d="M36.9997 37.0002L11 11.0005"></path></svg>';

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
  (label: '失控保护', route: AppRoutes.failsafe),
  (label: '履带混控', route: AppRoutes.tankMixing),
  (label: '报警提示', route: AppRoutes.alarms),
  (label: '固件升级', route: AppRoutes.firmware),
  (label: '帮助中心', route: AppRoutes.help),
];


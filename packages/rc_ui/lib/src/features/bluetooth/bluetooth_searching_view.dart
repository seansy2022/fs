
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

import 'package:rc_ui/src/core/app_assets.dart';

const _kBluetoothAccent = Color(0xFF00C6FF);

class BluetoothSearchingView extends StatefulWidget {
  const BluetoothSearchingView({super.key});

  @override
  State<BluetoothSearchingView> createState() => _BluetoothSearchingViewState();
}

class _BluetoothSearchingViewState extends State<BluetoothSearchingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: h * 300 / 1624,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '搜索中',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFonts.s20,
                        fontWeight: AppFonts.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: RotationTransition(
                        turns: _controller,
                        child: SvgPicture.asset(
                          AppAssets.loading,
                          colorFilter: const ColorFilter.mode(
                            _kBluetoothAccent,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: h * 410 / 1624,
                child: const Text(
                  '正在搜索附近蓝牙设备...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7DA2CE),
                    fontSize: AppFonts.s14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

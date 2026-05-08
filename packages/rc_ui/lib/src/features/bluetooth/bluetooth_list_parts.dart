
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

import 'package:rc_ui/src/core/app_assets.dart';

const _kBluetoothAccent = Color(0xFF00C6FF);

class BluetoothSearchingHint extends StatefulWidget {
  const BluetoothSearchingHint({super.key, this.text = 'Searching'});

  final String text;

  @override
  State<BluetoothSearchingHint> createState() => _BluetoothSearchingHintState();
}

class _BluetoothSearchingHintState extends State<BluetoothSearchingHint>
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.text,
          style: TextStyle(
            color: Colors.white,
            fontSize: AppFonts.s14,
            fontWeight: AppFonts.w700,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 14,
          height: 14,
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
    );
  }
}

class BluetoothStatusText extends StatelessWidget {
  const BluetoothStatusText({super.key, required this.connected, this.connectedLabel = 'Connected', this.disconnectedLabel = 'Disconnected'});

  final bool connected;
  final String connectedLabel;
  final String disconnectedLabel;

  @override
  Widget build(BuildContext context) {
    return Text(
      connected ? connectedLabel : disconnectedLabel,
      style: TextStyle(
        color: connected ? _kBluetoothAccent : const Color(0xFF7DA2CE),
        fontSize: AppFonts.s14,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class MixingChannelRow extends StatelessWidget {
  const MixingChannelRow({
    super.key,
    required this.selectedChannel,
    this.responsive = false,
    this.fontSize = AppFonts.s14,
    this.onTap,
  });

  final String selectedChannel;
  final bool responsive;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = _body();
    return _frame(child: body);
  }

  Widget _frame({required Widget child}) {
    return SizedBox(width: double.infinity, child: child);
  }

  Widget _body() {
    if (onTap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: body,
    );
  }

  Widget get body {
    return Row(
      children: [
        Text(
          '混控通道',
          style: TextStyle(color: AppColors.text, fontSize: fontSize),
        ),
        const Spacer(),
        Text(
          selectedChannel,
          style: TextStyle(color: const Color(0xFF7DA2CE), fontSize: fontSize),
        ),
        const SizedBox(width: 2),
        Icon(Icons.chevron_right, size: 20, color: Color(0xFF7DA2CE)),
      ],
    );
  }
}

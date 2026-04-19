import 'package:flutter/material.dart';
import 'package:rc_ui/src/elements/button/rc_icon_button.dart';

class CurveTabs extends StatelessWidget {
  const CurveTabs({
    super.key,
    required this.curves,
    required this.active,
    required this.onSelect,
  });

  final List<(String, String)> curves;
  final String active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < curves.length; i++) ...[
          Expanded(child: _item(curves[i].$1, curves[i].$2)),
          if (i != curves.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _item(String key, String text) {
    return RCIconButton(
      text: text,
      active: key == active,
      type: RCIconButtonType.textButton,
      width: double.infinity,
      size: 40, // 调整高度为 40
      isSquare: false,
      padding: EdgeInsets.zero,
      onTap: () => onSelect(key),
    );
  }
}

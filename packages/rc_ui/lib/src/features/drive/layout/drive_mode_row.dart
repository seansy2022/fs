import 'package:flutter/material.dart';

import 'drive_layout.dart';
import 'drive_mode_option.dart';

class DriveModeRow extends StatelessWidget {
  const DriveModeRow({super.key, required this.value, required this.onChanged});

  final DriveLayout value;
  final ValueChanged<DriveLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _item(DriveLayout.rear),
        const SizedBox(width: 12),
        _item(DriveLayout.mixed),
        const SizedBox(width: 12),
        _item(DriveLayout.front),
      ],
    );
  }

  Widget _item(DriveLayout mode) {
    return Expanded(
      child: DriveModeOption(
        mode: mode,
        selected: value == mode,
        onTap: () => onChanged(mode),
      ),
    );
  }
}

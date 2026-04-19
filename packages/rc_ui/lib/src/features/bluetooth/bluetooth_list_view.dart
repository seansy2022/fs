
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

import '../../core/models/ui_models.dart';

import 'bluetooth_list_parts.dart';

class BluetoothListView extends StatelessWidget {
  const BluetoothListView({
    super.key,
    required this.devices,
    required this.isScanning,
    required this.onTapDevice,
  });

  final List<UiBluetoothDevice> devices;
  final bool isScanning;
  final ValueChanged<int> onTapDevice;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isScanning)
          const Padding(
            padding: EdgeInsets.fromLTRB(AppDimens.gapL, 8, AppDimens.gapL, 6),
            child: BluetoothSearchingHint(),
          ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppDimens.gapL,
              isScanning ? 0 : 8,
              AppDimens.gapL,
              AppDimens.gapL,
            ),
            children: [_DeviceCard(devices: devices, onTapDevice: onTapDevice)],
          ),
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.devices, required this.onTapDevice});

  final List<UiBluetoothDevice> devices;
  final ValueChanged<int> onTapDevice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF233854)),
      ),
      child: Column(children: _rows(44)),
    );
  }

  List<Widget> _rows(double rowHeight) {
    return devices.asMap().entries.map((e) {
      final i = e.key;
      final d = e.value;
      return Container(
        height: rowHeight,
        decoration: BoxDecoration(
          border: i == 0
              ? null
              : const Border(top: BorderSide(color: Color(0xFF233854))),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTapDevice(d.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    d.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: AppFonts.s16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BluetoothStatusText(connected: d.connected),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

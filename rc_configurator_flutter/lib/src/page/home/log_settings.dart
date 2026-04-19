import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';
import 'package:rc_ble/rc_ble.dart';

import '../../provider/bluetooth_log_provider.dart';

class BluetoothLogSettingsPage extends ConsumerStatefulWidget {
  const BluetoothLogSettingsPage({super.key});

  @override
  ConsumerState<BluetoothLogSettingsPage> createState() =>
      _BluetoothLogSettingsPageState();
}

class _BluetoothLogSettingsPageState
    extends ConsumerState<BluetoothLogSettingsPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(ref.read(bluetoothLogProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bluetoothLogProvider);
    final controller = ref.read(bluetoothLogProvider.notifier);
    return TechShell(
      child: Column(
        children: [
          TopAppBar(
            title: '日志设置',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimens.gapL),
              children: [
                CellSwitchWidget(
                  title: '蓝牙日志',
                  value: state.enabled,
                  onChanged: (v) => unawaited(controller.setEnabled(v)),
                ),
                const SizedBox(height: AppDimens.gapM),
                if (state.loading)
                  const Center(child: CircularProgressIndicator())
                else
                  ...state.logs.map(_item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BluetoothLogEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.gapM),
      padding: const EdgeInsets.all(AppDimens.gapM),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_fmt(entry.timestampMs)}  ${entry.direction}  ${entry.command}',
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: AppFonts.s11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.dataText,
            style: const TextStyle(color: AppColors.text, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _fmt(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    final ms = (dt.millisecond ~/ 10).toString().padLeft(2, '0');
    return '$hh:$mm:$ss.$ms';
  }
}

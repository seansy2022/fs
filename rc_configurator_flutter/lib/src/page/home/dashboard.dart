import 'package:flutter/material.dart';

import 'package:rc_ui/rc_ui.dart';
import '../../types.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.telemetry,
    required this.channels,
    required this.connectedDeviceName,
    required this.isBluetoothConnected,
    required this.onNavigate,
  });

  final Telemetry telemetry;
  final List<ChannelState> channels;
  final String connectedDeviceName;
  final bool isBluetoothConnected;
  final ValueChanged<Screen> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.gapL),
      children: [
        Container(
          // padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: HomeTopWidget(
                      isConnected: isBluetoothConnected,
                      deviceName: connectedDeviceName,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.gapM),
        Row(
          children: [
            Expanded(
              child: HomeMetric(
                label: 'TX电压',
                value: _voltageText(telemetry.txVoltage, isBluetoothConnected),
                unit: _voltageUnit(telemetry.txVoltage, isBluetoothConnected),
              ),
            ),
            const SizedBox(width: AppDimens.gapM),
            Expanded(
              child: HomeMetric(
                label: 'RX电压',
                value: _voltageText(telemetry.rxVoltage, isBluetoothConnected),
                unit: _voltageUnit(telemetry.rxVoltage, isBluetoothConnected),
              ),
            ),
            const SizedBox(width: AppDimens.gapM),
            Expanded(
              child: HomeMetric(
                label: '信号强度',
                value: _rssiText(
                  telemetry.signalStrength,
                  isBluetoothConnected,
                ),
                unit: _rssiUnit(telemetry.signalStrength, isBluetoothConnected),
                emphasize: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.gapM),
        HomeCenterWidget(
          items: channels
              .take(4)
              .map((ch) => HomeCenterItem(label: ch.id, state: ch.value))
              .toList(),
        ),
        const SizedBox(height: AppDimens.gapM),
        CellIconWidget(enableHighlight: true, title: '通道行程', onTap: () => onNavigate(Screen.channels)),
        const SizedBox(height: AppDimens.gapM),
        CellIconWidget( enableHighlight: true,   title: '通道反向', onTap: () => onNavigate(Screen.reverse)),
        const SizedBox(height: AppDimens.gapM),
        CellIconWidget(
          enableHighlight: true, 
          title: '模型选择',
          onTap: () => onNavigate(Screen.modelSelection),
        ),
      ],
    );
  }

  String _voltageText(double value, bool isConnected) {
    if (!_hasVoltageData(value, isConnected)) return '-';
    return value.toStringAsFixed(1);
  }

  String _voltageUnit(double value, bool isConnected) {
    return _hasVoltageData(value, isConnected) ? 'V' : '-';
  }

  String _rssiText(int value, bool isConnected) {
    if (!_hasRssiData(value, isConnected)) return '-';
    return '$value';
  }

  String _rssiUnit(int value, bool isConnected) {
    return _hasRssiData(value, isConnected) ? 'dBm' : '-';
  }

  bool _hasVoltageData(double value, bool isConnected) {
    return isConnected && value >= 0;
  }

  bool _hasRssiData(int value, bool isConnected) {
    return isConnected && value < 0;
  }
}

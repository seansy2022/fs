import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rc_ui/rc_ui.dart';
import '../../provider/app_state_models.dart';
import '../../types.dart';

class Mixing extends StatelessWidget {
  const Mixing({
    super.key,
    required this.settings,
    required this.protocol,
    required this.onUpdateSettings,
    this.onReset,
  });

  final MixingSettings settings;
  final RcProtocolState protocol;
  final ValueChanged<MixingSettings> onUpdateSettings;
  final VoidCallback? onReset;
  static const _channels = [
    'CH3',
    'CH4',
    'CH5',
    'CH6',
    'CH7',
    'CH8',
    'CH9',
    'CH10',
    'CH11',
  ];

  @override
  Widget build(BuildContext context) {
    final modes = <(String, String, bool)>[
      ('4WS', '四轮转向', protocol.fourWheelSteer.enabled),
      ('TRACK', '履带混控', protocol.trackMixing.enabled),
      ('DRIVE', '驱动混控', protocol.driveMixing.enabled),
      ('BRAKE', '刹车混控', protocol.brakeMixing.enabled),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppDimens.gapL),
      children: [
        ...modes.expand((mode) {
          final enabled = mode.$3;
          return [
            CellSwitchWidget(
              title: mode.$2,
              value: enabled,
              onChanged: (v) =>
                  onUpdateSettings(_modeSettings(mode.$1, enabled: v)),
            ),
            if (enabled) ...[
              const SizedBox(height: 16),
              _resetItem(),
              const SizedBox(height: 16),
              _modePanel(context, mode.$1),
              // const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
          ];
        }),
      ],
    );
  }

  Widget _resetItem() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onReset,
      child: Row(
        children: [
          const Text(
            '复位',
            style: TextStyle(color: AppColors.text, fontSize: 12),
          ),
          const Spacer(),
          Icon(
            LucideIcons.refreshCw,
            color: const Color(0xFF7DA2CE),
            size: AppDimens.compactIcon(AppDimens.iconM) + 2,
          ),
        ],
      ),
    );
  }

  Widget _modePanel(BuildContext context, String mode) {
    if (mode == '4WS') {
      final value = _modeSettings(mode, enabled: true);
      return FourLunControl(
        selectedChannel: value.selectedChannel,
        ratio: value.ratio,
        direction: value.direction,
        onChannelTap: () =>
            _showChannelSheet(context, mode, value.selectedChannel),
        onRatioChange: (v) =>
            onUpdateSettings(_modeSettings(mode, enabled: true, ratio: v)),
        onDirectionChange: (v) =>
            onUpdateSettings(_modeSettings(mode, enabled: true, direction: v)),
        onLayoutChange: (r, d) => onUpdateSettings(
          _modeSettings(mode, enabled: true, ratio: r, direction: d),
        ),
      );
    }
    if (mode == 'TRACK') {
      final value = _modeSettings(mode, enabled: true);
      return TankControl(
        selectedChannel: value.selectedChannel,
        ratio: value.ratio,
        direction: value.direction,
        forwardRatio: protocol.trackMixing.forwardRatio,
        backwardRatio: protocol.trackMixing.backwardRatio,
        leftRatio: protocol.trackMixing.leftRatio,
        rightRatio: protocol.trackMixing.rightRatio,
        onControlChange: (ratio, direction) => onUpdateSettings(
          _modeSettings(
            mode,
            enabled: true,
            ratio: ratio,
            direction: direction,
          ),
        ),
      );
    }
    if (mode == 'DRIVE') {
      final value = _modeSettings(mode, enabled: true);
      return DriveMixingControl(
        selectedChannel: value.selectedChannel,
        ratio: value.ratio,
        mode: _driveModeFromDirection(value.direction),
        onChannelTap: () =>
            _showChannelSheet(context, mode, value.selectedChannel),
        onRatioChange: (v) =>
            onUpdateSettings(_modeSettings(mode, enabled: true, ratio: v)),
        onModeChange: (next) => onUpdateSettings(
          _modeSettings(
            mode,
            enabled: true,
            direction: _driveDirectionFromMode(next),
          ),
        ),
      );
    }
    final value = _modeSettings(mode, enabled: true);
    return BrakeMixingControl(
      selectedChannel: value.selectedChannel,
      ratio: value.ratio,
      curve: value.curve,
      onChannelTap: () =>
          _showChannelSheet(context, mode, value.selectedChannel),
      onRatioChange: (v) =>
          onUpdateSettings(_modeSettings(mode, enabled: true, ratio: v)),
      onCurveChange: (v) =>
          onUpdateSettings(_modeSettings(mode, enabled: true, curve: v)),
    );
  }

  void _showChannelSheet(
    BuildContext context,
    String mode,
    String selectedChannel,
  ) {
    AlertSelectionSheet.show(
      context,
      title: '混控通道',
      options: _channels,
      selectedOption: selectedChannel,
      titleFontSize: 14,
      optionFontSize: 14,
      onOptionSelected: (channel) => onUpdateSettings(
        _modeSettings(mode, enabled: true, selectedChannel: channel),
      ),
    );
  }

  MixingSettings _modeSettings(
    String mode, {
    required bool enabled,
    int? ratio,
    int? curve,
    String? direction,
    String? selectedChannel,
  }) {
    if (mode == '4WS') {
      final snap = protocol.fourWheelSteer;
      final currentDirection = _cachedFourWheelDirection(settings.direction);
      return settings.copyWith(
        activeMode: mode,
        enabled: enabled,
        selectedChannel: selectedChannel ?? _protocolChannelToUi(snap.channel),
        ratio: (ratio ?? snap.ratio).clamp(0, 100),
        direction:
            direction ??
            currentDirection ??
            _fourWheelDirectionFromMode(snap.mode),
      );
    }
    if (mode == 'TRACK') {
      final focus = _trackFocusValue();
      return settings.copyWith(
        activeMode: mode,
        enabled: enabled,
        ratio: (ratio ?? focus.$1).clamp(-100, 100),
        direction: direction ?? focus.$2,
      );
    }
    if (mode == 'DRIVE') {
      final snap = protocol.driveMixing;
      final modeRatio = snap.frontRatio == 100
          ? 100 - snap.rearRatio
          : snap.frontRatio - 100;
      final modeDirection = snap.mode == 0
          ? 'REAR'
          : snap.mode == 1
          ? 'MIXED'
          : 'FRONT';
      return settings.copyWith(
        activeMode: mode,
        enabled: enabled,
        selectedChannel: selectedChannel ?? _protocolChannelToUi(snap.channel),
        ratio: (ratio ?? modeRatio).clamp(-100, 100),
        direction: direction ?? modeDirection,
      );
    }
    final brake = protocol.brakeMixing;
    return settings.copyWith(
      activeMode: mode,
      enabled: enabled,
      selectedChannel: selectedChannel ?? _protocolChannelToUi(brake.channel),
      ratio: (ratio ?? brake.ratio).clamp(0, 100),
      curve: (curve ?? brake.curve).clamp(-100, 100),
    );
  }

  (int, String) _trackFocusValue() {
    final snap = protocol.trackMixing;
    final values = <(int, String)>[
      (snap.forwardRatio, 'SAME'),
      (-snap.backwardRatio, 'SAME'),
      (-snap.leftRatio, 'OPPOSITE'),
      (snap.rightRatio, 'OPPOSITE'),
    ];
    values.sort((a, b) => b.$1.abs().compareTo(a.$1.abs()));
    return values.first;
  }

  String _fourWheelDirectionFromMode(int mode) {
    return switch (mode.clamp(0, 3)) {
      1 => '4WS_FRONT_OPPOSITE',
      2 => '4WS_REAR_SAME',
      3 => '4WS_REAR_OPPOSITE',
      _ => '4WS_FRONT_SAME',
    };
  }

  String? _cachedFourWheelDirection(String direction) {
    if (direction.isEmpty) return '';
    const values = <String>{
      '4WS_FRONT_SAME',
      '4WS_FRONT_OPPOSITE',
      '4WS_REAR_SAME',
      '4WS_REAR_OPPOSITE',
    };
    return values.contains(direction) ? direction : null;
  }

  String _protocolChannelToUi(int idx) => 'CH${idx.clamp(2, 10) + 1}';

  DriveLayout _driveModeFromDirection(String direction) {
    return switch (direction) {
      'FRONT' => DriveLayout.front,
      'REAR' => DriveLayout.rear,
      _ => DriveLayout.mixed,
    };
  }

  String _driveDirectionFromMode(DriveLayout mode) {
    return switch (mode) {
      DriveLayout.front => 'FRONT',
      DriveLayout.rear => 'REAR',
      DriveLayout.mixed => 'MIXED',
    };
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../../core/providers.dart';
import '../../controllers/settings_controller.dart';
import '../../models/app_settings_state.dart';
import 'gyro_calibration_page.dart';
import 'package:controller_app/src/core/localization/app_localizations.dart';

const gyroCalibrationEntryKey = ValueKey<String>('gyro-calibration-entry');
const gyroTypeValueKey = ValueKey<String>('gyro-type-value');

/// 体感控制 SVG 的原始画板尺寸；所有子组件均以此坐标进行等比缩放。
const _gyroDesignWidth = 1216.0;
const _gyroDesignHeight = 184.0;

/// 设置页的体感控制区，逐项对应设计 SVG 中的元素与坐标。
class GyroControlSection extends ConsumerWidget {
  const GyroControlSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final mode = settings.gyroMode;
    final controller = ref.read(appSettingsProvider.notifier);
    final canSelectGyroHand =
        mode == GyroMode.directionOnly || mode == GyroMode.throttleOnly;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 设置页可能比 SVG 画板窄，按宽度等比缩小而非重排坐标。
        final width = math.min(constraints.maxWidth, _gyroDesignWidth);
        final scale = width / _gyroDesignWidth;
        return SizedBox(
          width: width,
          height: _gyroDesignHeight * scale,
          child: Stack(
            children: [
              const _GyroBackground(),
              _GyroSvgText(
                text: '体感控制',
                left: 32 * scale,
                top: 24 * scale,
                fontSize: 28 * scale,
                color: AppColors.text,
              ),
              _GyroCalibrationButton(
                scale: scale,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const GyroCalibrationPage(),
                  ),
                ),
              ),
              _GyroSvgText(
                text: '体感类型',
                left: 498 * scale,
                top: 24 * scale,
                fontSize: 28 * scale,
                color: AppColors.text,
              ),
              _GyroTypeValue(
                scale: scale,
                label: _gyroModeLabel(context, mode),
                onTap: () => _showGyroTypePicker(context, mode, controller),
              ),
              _GyroDivider(scale: scale),
              _GyroHandModeSegments(
                scale: scale,
                selectedMode: settings.gyroHandMode,
                enabled: canSelectGyroHand,
                onSelected: controller.setGyroHandMode,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GyroBackground extends StatelessWidget {
  const _GyroBackground();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(child: ColoredBox(color: Color(0x661B2D4D)));
  }
}

class _GyroCalibrationButton extends StatelessWidget {
  const _GyroCalibrationButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 32 * scale,
      top: 80 * scale,
      width: 260 * scale,
      height: 64 * scale,
      child: GestureDetector(
        key: gyroCalibrationEntryKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4 * scale),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryBright, AppColors.primary],
            ),
          ),
          child: Center(
            child: Text(
              context.tr('体感控制校准'),
              style: TextStyle(
                color: AppColors.bg,
                fontSize: 24 * scale,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GyroTypeValue extends StatelessWidget {
  const _GyroTypeValue({
    required this.scale,
    required this.label,
    required this.onTap,
  });

  final double scale;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 1036 * scale,
      top: 16 * scale,
      width: 148 * scale,
      height: 56 * scale,
      child: GestureDetector(
        key: gyroTypeValueKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceHighest,
            borderRadius: BorderRadius.circular(4 * scale),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 28 * scale,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GyroDivider extends StatelessWidget {
  const _GyroDivider({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 498 * scale,
      top: 87 * scale,
      width: 686 * scale,
      height: scale,
      child: const ColoredBox(color: Color(0xFF233854)),
    );
  }
}

/// 单通道体感模式下选择剩余触控通道的操作区域。
class _GyroHandModeSegments extends StatelessWidget {
  const _GyroHandModeSegments({
    required this.scale,
    required this.selectedMode,
    required this.enabled,
    required this.onSelected,
  });

  final double scale;
  final GyroHandMode selectedMode;
  final bool enabled;
  final ValueChanged<GyroHandMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 704 * scale,
      top: 100 * scale,
      width: 480 * scale,
      height: 64 * scale,
      child: Row(
        children: [
          _GyroHandModeSegment(
            label: '左手',
            width: 160 * scale,
            fontSize: 28 * scale,
            selected: enabled && selectedMode == GyroHandMode.left,
            enabled: enabled,
            onTap: () => onSelected(GyroHandMode.left),
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(4 * scale),
            ),
          ),
          _GyroHandModeSegment(
            label: '右手',
            width: 160 * scale,
            fontSize: 28 * scale,
            selected: enabled && selectedMode == GyroHandMode.right,
            enabled: enabled,
            onTap: () => onSelected(GyroHandMode.right),
          ),
          _GyroHandModeSegment(
            label: '双手',
            width: 160 * scale,
            fontSize: 28 * scale,
            selected: enabled && selectedMode == GyroHandMode.dual,
            enabled: enabled,
            onTap: () => onSelected(GyroHandMode.dual),
            borderRadius: BorderRadius.horizontal(
              right: Radius.circular(4 * scale),
            ),
          ),
        ],
      ),
    );
  }
}

class _GyroHandModeSegment extends StatelessWidget {
  const _GyroHandModeSegment({
    required this.label,
    required this.width,
    required this.fontSize,
    required this.enabled,
    required this.onTap,
    this.selected = false,
    this.borderRadius = BorderRadius.zero,
  });

  final String label;
  final double width;
  final double fontSize;
  final bool enabled;
  final VoidCallback onTap;
  final bool selected;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final localizedLabel = context.tr(label);
    final useCompactFont =
        Localizations.localeOf(context).languageCode == 'en' &&
        localizedLabel.length > label.length;

    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: GestureDetector(
          key: ValueKey<String>('gyro-hand-$label'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: width,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? null : const Color(0x661B2D4D),
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x0000C6FF), Color(0x8000C6FF)],
                    )
                  : null,
              borderRadius: borderRadius,
              border: Border.all(
                color: selected ? AppColors.primaryBright : AppColors.primary,
                width: 1,
              ),
            ),
            child: Text(
              localizedLabel,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppColors.text : const Color(0xFF7DA2CE),
                fontSize: useCompactFont ? fontSize * 0.86 : fontSize,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GyroSvgText extends StatelessWidget {
  const _GyroSvgText({
    required this.text,
    required this.left,
    required this.top,
    required this.fontSize,
    required this.color,
  });

  final String text;
  final double left;
  final double top;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Text(
        context.tr(text),
        style: TextStyle(color: color, fontSize: fontSize, height: 1),
      ),
    );
  }
}

void _showGyroTypePicker(
  BuildContext context,
  GyroMode current,
  SettingsController controller,
) {
  final options = <String>[
    context.tr('方向'),
    context.tr('油门'),
    context.tr('all'),
  ];
  AlertListDialog.show(
    context,
    title: context.tr('体感类型'),
    width: 280,
    options: options,
    selectedOption: _gyroModeLabel(context, current),
    onOptionSelected: (value) {
      controller.setGyroMode(switch (value) {
        final direction when direction == context.tr('方向') =>
          GyroMode.directionOnly,
        final throttle when throttle == context.tr('油门') =>
          GyroMode.throttleOnly,
        _ => GyroMode.all,
      });
    },
  );
}

String _gyroModeLabel(BuildContext context, GyroMode mode) {
  return switch (mode) {
    GyroMode.directionOnly => context.tr('方向'),
    GyroMode.throttleOnly => context.tr('油门'),
    GyroMode.all => context.tr('all'),
  };
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../widgets/numeric_input_dialog.dart';
import '../widgets/settings_workspace.dart';
import '../widgets/tank_mixing_panel.dart';

const tankMixingEnabledSwitchKey = ValueKey<String>('tank-mixing-enabled');

class TankMixingPage extends ConsumerWidget {
  const TankMixingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsWorkspace(
      activeRoute: AppRoutes.tankMixing,
      onBack: () => Navigator.of(context).pop(),
      content: const TankMixingContent(),
    );
  }
}

class TankMixingContent extends ConsumerStatefulWidget {
  const TankMixingContent({super.key});

  @override
  ConsumerState<TankMixingContent> createState() => _TankMixingContentState();
}

class _TankMixingContentState extends ConsumerState<TankMixingContent> {
  _TankMixDirection? _selectedDirection;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);
    final enabled = settings.tankMixingEnabled;
    final forward = settings.tankForwardPercent.round().clamp(-100, 100);
    final backward = settings.tankReversePercent.round().clamp(-100, 100);
    final left = settings.tankLeftTurnPercent.round().clamp(-100, 100);
    final right = settings.tankRightTurnPercent.round().clamp(-100, 100);

    return Column(
      children: [
        TankMixingPanel(
          enabled: enabled,
          onEnabledTap: () => controller.setTankMixingEnabled(!enabled),
          forwardValue: forward,
          leftTurnValue: left,
          rightTurnValue: right,
          backwardValue: backward,
          forwardSelected: _selectedDirection == _TankMixDirection.forward,
          backwardSelected: _selectedDirection == _TankMixDirection.backward,
          leftTurnSelected: _selectedDirection == _TankMixDirection.left,
          rightTurnSelected: _selectedDirection == _TankMixDirection.right,
          leftTrackValue: left,
          rightTrackValue: right,
          onForwardTap: () => _selectAndEdit(
            context,
            direction: _TankMixDirection.forward,
            title: '前进',
            initialValue: forward,
            onChanged: (value) =>
                controller.updateTankMixRatios(forward: value.toDouble()),
          ),
          onBackwardTap: () => _selectAndEdit(
            context,
            direction: _TankMixDirection.backward,
            title: '后退',
            initialValue: backward,
            onChanged: (value) =>
                controller.updateTankMixRatios(reverse: value.toDouble()),
          ),
          onLeftTap: () => _selectAndEdit(
            context,
            direction: _TankMixDirection.left,
            title: '左转',
            initialValue: left,
            onChanged: (value) =>
                controller.updateTankMixRatios(leftTurn: value.toDouble()),
          ),
          onRightTap: () => _selectAndEdit(
            context,
            direction: _TankMixDirection.right,
            title: '右转',
            initialValue: right,
            onChanged: (value) =>
                controller.updateTankMixRatios(rightTurn: value.toDouble()),
          ),
        ),
      ],
    );
  }

  Future<void> _selectAndEdit(
    BuildContext context, {
    required _TankMixDirection direction,
    required String title,
    required int initialValue,
    required ValueChanged<int> onChanged,
  }) async {
    if (!ref.read(appSettingsProvider).tankMixingEnabled) {
      return;
    }
    setState(() => _selectedDirection = direction);
    final raw = await NumericInputDialog.show(
      context,
      title: title,
      initialValue: initialValue.toString(),
      unit: '%',
      allowSigned: true,
      allowDecimal: false,
      maxAbsValue: 100,
      maxLength: 4,
    );
    final parsed = int.tryParse(raw?.trim() ?? '');
    if (parsed == null) return;
    // 履带混控支持正反向比例，统一限制为 -100%–100%。
    onChanged(parsed.clamp(-100, 100));
  }
}

enum _TankMixDirection { forward, backward, left, right }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../widgets/numeric_input_dialog.dart';
import '../widgets/settings_workspace.dart';
import '../widgets/tank_mixing_panel.dart';

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
    final left = settings.trackMixLeft.round().clamp(-100, 100);
    final right = settings.trackMixRight.round().clamp(-100, 100);

    return Column(
      children: [
        TankMixingPanel(
          forwardValue: left > 0 ? left : 0,
          leftTurnValue: left < 0 ? -left : 0,
          rightTurnValue: right > 0 ? right : 0,
          backwardValue: right < 0 ? -right : 0,
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
            initialValue: left > 0 ? left : 0,
            onChanged: (value) =>
                controller.updateTrackMix(left: value.toDouble()),
          ),
          onBackwardTap: () => _selectAndEdit(
            context,
            direction: _TankMixDirection.backward,
            title: '后退',
            initialValue: right < 0 ? -right : 0,
            onChanged: (value) =>
                controller.updateTrackMix(right: -value.toDouble()),
          ),
          onLeftTap: () => _selectAndEdit(
            context,
            direction: _TankMixDirection.left,
            title: '左转',
            initialValue: left < 0 ? -left : 0,
            onChanged: (value) =>
                controller.updateTrackMix(left: -value.toDouble()),
          ),
          onRightTap: () => _selectAndEdit(
            context,
            direction: _TankMixDirection.right,
            title: '右转',
            initialValue: right > 0 ? right : 0,
            onChanged: (value) =>
                controller.updateTrackMix(right: value.toDouble()),
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
    setState(() => _selectedDirection = direction);
    final raw = await NumericInputDialog.show(
      context,
      title: title,
      initialValue: initialValue.toString(),
      unit: '%',
      allowDecimal: false,
      maxLength: 3,
    );
    final parsed = int.tryParse(raw?.trim() ?? '');
    if (parsed == null) return;
    onChanged(parsed.clamp(0, 100));
  }
}

enum _TankMixDirection { forward, backward, left, right }

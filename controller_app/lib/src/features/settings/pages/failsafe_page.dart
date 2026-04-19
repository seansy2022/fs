import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../widgets/settings_workspace.dart';

class FailsafePage extends ConsumerStatefulWidget {
  const FailsafePage({super.key});

  @override
  ConsumerState<FailsafePage> createState() => _FailsafePageState();
}

class _FailsafePageState extends ConsumerState<FailsafePage> {
  @override
  Widget build(BuildContext context) {
    return SettingsWorkspace(
      activeRoute: AppRoutes.failsafe,
      onBack: () => Navigator.of(context).pop(),
      content: const FailsafeContent(),
    );
  }
}

class FailsafeContent extends ConsumerStatefulWidget {
  const FailsafeContent({super.key});

  @override
  ConsumerState<FailsafeContent> createState() => _FailsafeContentState();
}

class _FailsafeContentState extends ConsumerState<FailsafeContent> {
  @override
  Widget build(BuildContext context) {
    final connected =
        ref.watch(receiverConnectionProvider).valueOrNull ==
        ReceiverConnectionState.connected;

    return Column(
      children: [
        const _FailsafeChannelStrip(title: '娌归棬'),
        const SizedBox(height: 8),
                    const _FailsafeChannelStrip(title: '方向'),
        const Spacer(),
        Center(
          child: SizedBox(
            width: 174,
            height: 44,
            child: PrimaryButton(
              text: 'TEST',
              type: PrimaryButtonType.normal,
              enabled: connected,
              padding: EdgeInsets.zero,
              onTap: connected
                  ? () => Navigator.of(context).pushNamed(AppRoutes.control)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FailsafeChannelStrip extends StatelessWidget {
  const _FailsafeChannelStrip({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SettingsStrip(
      // height: 88,
      child: Row(
        children: [
          SizedBox(
            // width: 180,
            child: Text(
              title,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
            ),
          ),
          Spacer(),
          ItemButton(text: '0%', selected: true, fontSize: 14, onTap: () {}),
          const SizedBox(width: 12),
          ItemButton(
            text: '固定值',
            selected: false,
            fontSize: 14,
            width: 74,
            height: 28,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

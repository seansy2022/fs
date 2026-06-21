import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../widgets/firmware_upgrade_progress_dialog.dart';
import '../widgets/settings_workspace.dart';

const _firmwareVersionLabel = '1.0.6';
const _firmwareVersionCode = 0x0106;
const _firmwareAssetPath = 'assets/firmware/APP.bin';

class FirmwareUpgradePage extends StatelessWidget {
  const FirmwareUpgradePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsWorkspace(
      activeRoute: AppRoutes.firmware,
      onBack: () => Navigator.of(context).pop(),
      content: const FirmwareUpgradeContent(),
    );
  }
}

class FirmwareUpgradeContent extends ConsumerStatefulWidget {
  const FirmwareUpgradeContent({super.key});

  @override
  ConsumerState<FirmwareUpgradeContent> createState() =>
      _FirmwareUpgradeContentState();
}

class _FirmwareUpgradeContentState
    extends ConsumerState<FirmwareUpgradeContent> {
  bool _working = false;

  Future<void> _startUpgrade(BuildContext context) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final repository = ref.read(receiverRepositoryProvider);
      if (repository.receiverInfo == null) {
        await repository.readReceiverInfo();
      }
      final info = await repository.readFirmwareInfo();
      if (!context.mounted) return;

      final result = await AlertIconWidget.show(
        context,
        title: '固件升级',
        message:
            '当前固件版本：${info.versionLabel}\n'
            '目标版本：$_firmwareVersionLabel ${_versionNote(info)}\n\n'
            '确定开始升级？升级过程中请勿断开连接。',
        cancelText: '取消',
        confirmText: '确定',
      );
      if (result != true || !context.mounted) return;

      final data = await rootBundle.load(_firmwareAssetPath);
      await repository.stopControlLoop();
      if (!context.mounted) return;
      await _showUpgradeDialog(
        context,
        repository.startUpgrade(Uint8List.sublistView(data)),
      );
    } catch (_) {
      if (!context.mounted) return;
      await AlertIconWidget.show(
        context,
        title: '无法升级',
        message: '请先连接接收机，并确认固件包可用。',
        confirmText: '确定',
      );
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  String _versionNote(ReceiverFirmwareInfo info) {
    if (_firmwareVersionCode > info.firmwareVersionCode) return '（最新版本）';
    if (_firmwareVersionCode < info.firmwareVersionCode) return '（旧版本）';
    return '（当前版本）';
  }

  Future<void> _showUpgradeDialog(
    BuildContext context,
    Stream<ReceiverUpgradeProgress> progress,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FirmwareProgressDialog(progress: progress),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FirmwareRow(
          label: _working
              ? '$_firmwareVersionLabel 升级中'
              : _firmwareVersionLabel,
          enabled: !_working,
          onTap: () => unawaited(_startUpgrade(context)),
        ),
      ],
    );
  }
}

class _FirmwareRow extends StatelessWidget {
  const _FirmwareRow({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettingsStrip(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: 36,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: enabled ? AppColors.text : AppColors.textDim,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textDim,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

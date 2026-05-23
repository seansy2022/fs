import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/app_constants.dart';
import '../../../core/providers.dart';
import '../widgets/firmware_upgrade_status_dialog.dart';
import '../widgets/settings_workspace.dart';

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

class FirmwareEntry {
  const FirmwareEntry({required this.versionLabel, required this.versionCode});

  final String versionLabel;
  final int versionCode;
}

class FirmwareUpgradeContent extends ConsumerStatefulWidget {
  const FirmwareUpgradeContent({super.key});

  @override
  ConsumerState<FirmwareUpgradeContent> createState() =>
      _FirmwareUpgradeContentState();
}

class _FirmwareUpgradeContentState
    extends ConsumerState<FirmwareUpgradeContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _localFirmwareEntries.length; i++) ...[
          _FirmwareRow(
            label: _localFirmwareEntries[i].versionLabel,
            onTap: () => _onFirmwareTap(context, _localFirmwareEntries[i]),
          ),
          const SizedBox(height: 8),
        ],
        _FirmwareRow(
          label: 'loading失败',
          onTap: () => _showPreviewDialog(context, _UpgradeFlow.failurePreview),
        ),
        const SizedBox(height: 8),
        _FirmwareRow(
          label: 'loading成功',
          onTap: () => _showPreviewDialog(context, _UpgradeFlow.successPreview),
        ),
      ],
    );
  }

  Future<void> _onFirmwareTap(BuildContext context, FirmwareEntry entry) async {
    final info = ref.read(receiverFirmwareInfoProvider).valueOrNull;
    if (info == null) {
      await AlertIconWidget.show(
        context,
        title: '无法升级',
        message: '请先连接接收机',
        confirmText: '确定',
      );
      return;
    }

    final currentVersion = info.firmwareVersionCode;
    final newVersion = entry.versionCode;
    String versionNote;
    if (newVersion > currentVersion) {
      versionNote = '（最新版本）';
    } else if (newVersion < currentVersion) {
      versionNote = '（旧版本）';
    } else {
      versionNote = '（当前版本）';
    }

    final result = await AlertIconWidget.show(
      context,
      title: '固件升级',
      message:
          '当前固件版本：${info.versionLabel}\n'
          '目标版本：${entry.versionLabel} $versionNote\n\n'
          '确定开始升级？升级过程中请勿断开连接。',
      cancelText: '取消',
      confirmText: '确定',
    );

    if (result == true && context.mounted) {
      unawaited(
        _showProgressDialog(
          context,
          outcome: FirmwareUpgradeStatusOutcome.success,
          autoCloseOnSuccess: true,
        ),
      );
    }
  }

  Future<void> _showPreviewDialog(
    BuildContext context,
    _UpgradeFlow flow,
  ) async {
    await FirmwareUpgradeStatusDialog.show(
      context,
      outcome: flow == _UpgradeFlow.failurePreview
          ? FirmwareUpgradeStatusOutcome.failure
          : FirmwareUpgradeStatusOutcome.success,
    );
  }

  Future<void> _showProgressDialog(
    BuildContext context, {
    required FirmwareUpgradeStatusOutcome outcome,
    bool autoCloseOnSuccess = false,
  }) {
    return FirmwareUpgradeStatusDialog.show(
      context,
      outcome: outcome,
      autoCloseOnSuccess: autoCloseOnSuccess,
    );
  }
}

final _localFirmwareEntries = demoFirmwarePackages
    .take(2)
    .map(
      (package) => FirmwareEntry(
        versionLabel: package.versionLabel,
        versionCode: _versionCodeFromLabel(package.versionLabel),
      ),
    )
    .toList(growable: false);

int _versionCodeFromLabel(String versionLabel) {
  final parts = versionLabel.split('.');
  if (parts.length < 2) return 0;
  final major = int.tryParse(parts[parts.length - 2]) ?? 0;
  final minor = int.tryParse(parts[parts.length - 1]) ?? 0;
  return (major << 8) | minor;
}

class _FirmwareRow extends StatelessWidget {
  const _FirmwareRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettingsStrip(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 36,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.text, fontSize: 14),
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

enum _UpgradeFlow { failurePreview, successPreview }

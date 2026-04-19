import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/app_constants.dart';
import '../../../core/providers.dart';
import '../widgets/settings_workspace.dart';

class FirmwareUpgradePage extends ConsumerStatefulWidget {
  const FirmwareUpgradePage({super.key});

  @override
  ConsumerState<FirmwareUpgradePage> createState() =>
      _FirmwareUpgradePageState();
}

class _FirmwareUpgradePageState extends ConsumerState<FirmwareUpgradePage> {
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
  DemoFirmwarePackage _selectedPackage = demoFirmwarePackages.first;
  ReceiverUpgradeProgress? _progress;
  bool _readingVersion = false;
  bool _upgrading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_readVersion());
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(receiverRepositoryProvider);
    final firmwareInfo =
        ref.watch(receiverFirmwareInfoProvider).valueOrNull ??
        repository.firmwareInfo;
    final connected =
        repository.connectionState == ReceiverConnectionState.connected;

    return ListView(
      children: [
        SettingsStrip(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                connected ? '已连接设备' : '未连接设备',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: AppFonts.s16,
                  fontWeight: AppFonts.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                connected
                    ? (repository.receiverInfo?.modelLabel ?? '接收机已连接')
                    : '请先连接接收机后再读取固件信息。',
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: _readingVersion ? '读取中...' : '读取当前固件版本',
                enabled: connected && !_readingVersion,
                onTap: _readVersion,
              ),
              if (firmwareInfo != null) ...[
                const SizedBox(height: 12),
                Text(
                  '当前版本：${firmwareInfo.versionLabel}',
                  style: const TextStyle(
                    color: AppColors.primaryBright,
                    fontSize: AppFonts.s16,
                    fontWeight: AppFonts.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SettingsStrip(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '演示固件包',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: AppFonts.s16,
                  fontWeight: AppFonts.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...demoFirmwarePackages.map((package) {
                final selected = package.id == _selectedPackage.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPackage = package),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0x2200C8FF)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryBright
                              : const Color(0xFF233854),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${package.label} ${package.versionLabel}',
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 15,
                                    fontWeight: AppFonts.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '大小 ${package.size} bytes',
                                  style: const TextStyle(
                                    color: AppColors.textDim,
                                    fontSize: AppFonts.s12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primaryBright,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
              PrimaryButton(
                text: _upgrading ? '升级中...' : '开始升级',
                enabled: connected && !_upgrading,
                onTap: () => _startUpgrade(context),
              ),
              if (_progress != null) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _progress!.fraction,
                  minHeight: 8,
                  backgroundColor: AppColors.surface,
                  color: _progress!.stage == ReceiverUpgradeStage.failed
                      ? Colors.redAccent
                      : AppColors.primaryBright,
                ),
                const SizedBox(height: 8),
                Text(
                  _progressLabel(_progress!),
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _readVersion() async {
    final repository = ref.read(receiverRepositoryProvider);
    if (repository.connectionState != ReceiverConnectionState.connected) {
      return;
    }
    setState(() => _readingVersion = true);
    try {
      await repository.readFirmwareInfo();
    } finally {
      if (mounted) {
        setState(() => _readingVersion = false);
      }
    }
  }

  Future<void> _startUpgrade(BuildContext context) async {
    final repository = ref.read(receiverRepositoryProvider);
    setState(() {
      _upgrading = true;
      _progress = const ReceiverUpgradeProgress(
        stage: ReceiverUpgradeStage.idle,
        sentChunks: 0,
        totalChunks: 0,
      );
    });
    await for (final progress in repository.startUpgrade(
      _selectedPackage.buildBytes(),
    )) {
      if (!mounted) {
        break;
      }
      setState(() {
        _progress = progress;
      });
    }
    if (mounted) {
      setState(() => _upgrading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_progressLabel(_progress!))));
    }
  }

  String _progressLabel(ReceiverUpgradeProgress progress) {
    switch (progress.stage) {
      case ReceiverUpgradeStage.idle:
        return '等待开始升级';
      case ReceiverUpgradeStage.enteringBoot:
        return '正在让接收机进入 Boot 模式';
      case ReceiverUpgradeStage.sendingLength:
        return '正在发送升级包长度';
      case ReceiverUpgradeStage.sendingPayload:
        return '正在发送固件数据 ${progress.sentChunks}/${progress.totalChunks}';
      case ReceiverUpgradeStage.completed:
        return '升级完成';
      case ReceiverUpgradeStage.failed:
        return progress.message ?? '升级失败';
    }
  }
}

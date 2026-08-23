import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers.dart';
import '../widgets/firmware_upgrade_progress_dialog.dart';
import '../widgets/settings_workspace.dart';

const _firmwareDownloadUrl =
    'https://flyskydownload.flyskytech.com/s/bin/shr_jt2dky5h';
const _firmwareLocalFileName = 'receiver_upgrade_firmware.bin';

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
  bool _downloading = false;

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
        title: AppText.tr('固件升级'),
        message:
            '${AppText.tr('当前固件版本：')}${info.versionLabel}\n'
            '\n'
            '${AppText.tr('将下载最新固件包并开始升级。升级过程中请勿断开连接。')}',
        cancelText: AppText.tr('取消'),
        confirmText: AppText.tr('确定'),
      );
      if (result != true || !context.mounted) return;

      setState(() => _downloading = true);
      final data = await _downloadFirmwareToLocal();
      if (mounted) {
        setState(() => _downloading = false);
      }
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
        title: AppText.tr('无法升级'),
        message: AppText.tr('请先连接接收机，并确认固件包可用。'),
        confirmText: AppText.tr('确定'),
      );
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  /// 下载固件到 App 缓存目录；仅在完整写入非空 BIN 后返回升级数据。
  Future<Uint8List> _downloadFirmwareToLocal() async {
    final cacheDirectory = await getApplicationCacheDirectory();
    final firmwareFile = File(
      '${cacheDirectory.path}${Platform.pathSeparator}$_firmwareLocalFileName',
    );
    final client = http.Client();
    try {
      final response = await client.send(
        http.Request('GET', Uri.parse(_firmwareDownloadUrl)),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('固件下载失败，状态码：${response.statusCode}');
      }

      final bytes = await response.stream.toBytes();
      if (bytes.isEmpty) {
        throw const FileSystemException('下载的固件包为空');
      }

      // 先完整写入本地文件，再读取该文件参与升级，避免使用旧的内置固件。
      await firmwareFile.writeAsBytes(bytes, flush: true);
      final localBytes = await firmwareFile.readAsBytes();
      if (localBytes.isEmpty) {
        throw const FileSystemException('本地固件包读取失败');
      }
      debugPrint(
        '[FirmwareUpgrade] 下载完成 path=${firmwareFile.path} '
        'bytes=${localBytes.length}',
      );
      return localBytes;
    } finally {
      client.close();
    }
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
          label: AppText.tr(
            _working ? (_downloading ? '下载固件中' : '升级中') : '升级版本',
          ),
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

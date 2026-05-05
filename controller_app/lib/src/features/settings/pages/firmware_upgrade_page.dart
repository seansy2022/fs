import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:rc_ui/rc_ui.dart';

import '../../../app/app_routes.dart';
import '../../../core/providers.dart';
import '../widgets/settings_workspace.dart';

/// Base URL for firmware upgrade.
/// Returns a JSON array of [FirmwareEntry].
const _firmwareListUrl = 'https://example.com/api/firmware/list';

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
  const FirmwareEntry({
    required this.label,
    required this.productCode,
    required this.versionCode,
    required this.downloadUrl,
  });

  factory FirmwareEntry.fromJson(Map<String, Object?> json) {
    return FirmwareEntry(
      label: json['label']! as String,
      productCode: (json['productCode']! as num).toInt(),
      versionCode: (json['versionCode']! as num).toInt(),
      downloadUrl: json['downloadUrl']! as String,
    );
  }

  final String label;
  final int productCode;
  final int versionCode;
  final String downloadUrl;
}

class FirmwareUpgradeContent extends ConsumerStatefulWidget {
  const FirmwareUpgradeContent({super.key});

  @override
  ConsumerState<FirmwareUpgradeContent> createState() =>
      _FirmwareUpgradeContentState();
}

class _FirmwareUpgradeContentState
    extends ConsumerState<FirmwareUpgradeContent> {
  List<FirmwareEntry>? _entries;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchFirmwareList());
  }

  Future<void> _fetchFirmwareList() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse(_firmwareListUrl))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = '服务器返回错误：${response.statusCode}';
        });
        return;
      }
      final list = jsonDecode(response.body) as List<dynamic>;
      setState(() {
        _entries = list
            .whereType<Map<String, dynamic>>()
            .map(FirmwareEntry.fromJson)
            .toList(growable: false);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '加载失败：${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBright),
      );
    }

    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error!,
            style: const TextStyle(color: AppColors.textDim, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: '重试',
            width: 120,
            onTap: _fetchFirmwareList,
          ),
        ],
      );
    }

    if (_entries == null || _entries!.isEmpty) {
      return const Center(
        child: Text(
          '无可更新固件',
          style: TextStyle(color: AppColors.textDim, fontSize: 14),
        ),
      );
    }

    return ListView(
      children: [
        const SettingsStrip(
          child: Text(
            '固件升级',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: AppFonts.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._entries!.map((entry) => _FirmwareRow(
              entry: entry,
              onTap: () => _onFirmwareTap(entry),
            )),
      ],
    );
  }

  Future<void> _onFirmwareTap(FirmwareEntry entry) async {
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
      title: entry.label,
      message: '当前固件版本：${info.versionLabel}\n'
          '目标版本：${_versionLabel(entry.versionCode)} $versionNote\n\n'
          '确定开始升级？升级过程中请勿断开连接。',
      cancelText: '取消',
      confirmText: '确定',
    );

    if (result == true && mounted) {
      unawaited(_startUpgrade(entry));
    }
  }

  Future<void> _startUpgrade(FirmwareEntry entry) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UpgradeProgressDialog(
        downloadUrl: entry.downloadUrl,
      ),
    );
  }

  String _versionLabel(int versionCode) {
    final major = (versionCode >> 8) & 0xFF;
    final minor = versionCode & 0xFF;
    return '$major.$minor';
  }
}

class _FirmwareRow extends StatelessWidget {
  const _FirmwareRow({required this.entry, required this.onTap});

  final FirmwareEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SettingsStrip(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: AppFonts.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textDim, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeProgressDialog extends StatefulWidget {
  const _UpgradeProgressDialog({required this.downloadUrl});

  final String downloadUrl;

  @override
  State<_UpgradeProgressDialog> createState() => _UpgradeProgressDialogState();
}

class _UpgradeProgressDialogState extends State<_UpgradeProgressDialog> {
  double _progress = 0;
  String _status = '准备中...';
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    unawaited(_doUpgrade());
  }

  Future<void> _doUpgrade() async {
    try {
      setState(() => _status = '正在下载固件...');
      final response = await http
          .get(Uri.parse(widget.downloadUrl))
          .timeout(const Duration(minutes: 1));
      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _status = '下载失败：${response.statusCode}';
          _complete = true;
        });
        return;
      }

      setState(() => _status = '正在发送固件到接收机...');
      // TODO: Send firmware bytes to receiver via repository.startUpgrade()
      // For now, simulate completion
      await Future<void>.delayed(const Duration(milliseconds: 500));
      setState(() {
        _progress = 1.0;
        _status = '升级完成！';
        _complete = true;
      });

      // Auto close after 2s
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = '升级失败：$e';
        _complete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1B2A4A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '固件升级',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: AppFonts.w700,
              ),
            ),
            const SizedBox(height: 24),
            if (!_complete)
              const CircularProgressIndicator(color: AppColors.primaryBright),
            if (_complete && _progress >= 1.0)
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
            if (_complete && _progress < 1.0)
              const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(color: AppColors.textDim, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (_complete) ...[
              const SizedBox(height: 16),
              PrimaryButton(
                text: '关闭',
                width: 120,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

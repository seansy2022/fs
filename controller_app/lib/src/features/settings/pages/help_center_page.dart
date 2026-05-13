import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

import '../widgets/settings_workspace.dart';

class HelpCenterContent extends StatelessWidget {
  const HelpCenterContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _manualDocuments.length; i++) ...[
          _ArrowItem(
            label: _manualDocuments[i].title,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      _HelpManualDetailPage(document: _manualDocuments[i]),
                ),
              );
            },
          ),
          if (i != _manualDocuments.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _HelpManualDetailPage extends StatelessWidget {
  const _HelpManualDetailPage({required this.document});

  final _ManualDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TechShell(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _HelpManualDetailContent(document: document),
          ),
        ),
      ),
    );
  }
}

class _HelpManualDetailContent extends StatelessWidget {
  const _HelpManualDetailContent({required this.document});

  final _ManualDocument document;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                document.title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: AppFonts.w700,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Icon(Icons.close, color: AppColors.text, size: 22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 2,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [0, 0.3334, 0.5092, 0.678, 1],
              colors: [
                Color.fromRGBO(126, 162, 207, 1),
                Color.fromRGBO(0, 198, 255, 1),
                Color.fromRGBO(146, 254, 157, 1),
                Color.fromRGBO(0, 200, 255, 1),
                Color.fromRGBO(125, 162, 206, 1),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighest.withValues(alpha: 0.42),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                document.body,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowItem extends StatelessWidget {
  const _ArrowItem({required this.label, required this.onTap});

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

class _ManualDocument {
  const _ManualDocument({required this.title, required this.body});

  final String title;
  final String body;
}

const _manualDocuments = <_ManualDocument>[
  _ManualDocument(
    title: '中文版说明书',
    body:
        '1. 给接收机上电并确认设备处于正常工作状态。\n'
        '2. 打开 App 后，可在首页进入配对、控制、设置等功能页面。\n'
        '3. 若需要修改通道、失控保护、报警提示或固件升级，请进入设置页面操作。\n'
        '4. 固件升级过程中请保持设备供电稳定，并确保蓝牙连接不要中断。\n'
        '5. 若出现异常提示，请先检查设备状态，再重新尝试相关操作。\n'
        '\n'
        '注意事项：\n'
        '- 车辆调试时请保证周围环境安全。\n'
        '- 修改参数前请确认当前模型处于可控状态。\n'
        '- 升级完成后建议重新连接设备并确认版本信息。',
  ),
  _ManualDocument(
    title: '英文版说明书',
    body:
        '1. Power on the receiver and make sure the device is working normally.\n'
        '2. Open the app and enter pairing, control, or settings from the home page.\n'
        '3. Use the settings page to configure channels, failsafe, alarms, and firmware upgrade.\n'
        '4. Keep the receiver powered on and the Bluetooth connection stable during firmware upgrade.\n'
        '5. If an error occurs, check the device status first and then try again.\n'
        '\n'
        'Notes:\n'
        '- Make sure the vehicle is in a safe environment before testing.\n'
        '- Confirm the model is controllable before changing parameters.\n'
        '- After upgrade, reconnect the device and verify the firmware version.',
  ),
];

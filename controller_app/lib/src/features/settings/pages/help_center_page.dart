import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

import '../widgets/settings_workspace.dart';

class HelpCenterContent extends StatelessWidget {
  const HelpCenterContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _ArrowItem(
          label: '说明书中文',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const _ManualDetailPage(
                topRightTitle: '中文说明书',
                contentTitle: '中文输出标题',
                content: _zhManualText,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _ArrowItem(
          label: '说明书英文',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const _ManualDetailPage(
                topRightTitle: '英文说明书',
                contentTitle: 'English Manual Title',
                content: _enManualText,
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
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: AppFonts.w600,
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
    );
  }
}

class _ManualDetailPage extends StatelessWidget {
  const _ManualDetailPage({
    required this.topRightTitle,
    required this.contentTitle,
    required this.content,
  });

  final String topRightTitle;
  final String contentTitle;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TechShell(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      topRightTitle,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: AppFonts.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.text),
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
                  child: ListView(
                    children: [
                      SettingsStrip(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contentTitle,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: AppFonts.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              content,
                              style: const TextStyle(
                                color: AppColors.textDim,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const String _zhManualText =
    '1. 设备开机后，请先确认电量与信号状态。\n'
    '2. 进入控制前，建议先完成通道与失控保护设置。\n'
    '3. 固件升级时请保持设备供电稳定，避免中断。\n\n'
    '安全提示：\n'
    '- 升级过程中请勿断电或退出应用。\n'
    '- 若升级失败，请重启设备后重试。\n'
    '- 如需更多帮助，请联系技术支持。';

const String _enManualText =
    '1. Check battery and signal status before operation.\n'
    '2. Configure channels and failsafe before driving.\n'
    '3. Keep stable power during firmware update.\n\n'
    'Safety Notes:\n'
    '- Do not power off during update.\n'
    '- Restart and retry if update fails.\n'
    '- Contact support for additional assistance.';

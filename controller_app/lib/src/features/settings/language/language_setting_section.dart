import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../provider/app_locale_provider.dart';
import '../widgets/settings_workspace.dart';

/// 基本设置中的语言选择入口。
class LanguageSettingSection extends ConsumerWidget {
  const LanguageSettingSection({super.key});

  @override
  /// 构建当前语言展示与选择入口。
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLocaleProvider);
    return SettingsStrip(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showLanguageDialog(context, ref, language),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.tr('语言'),
                style: const TextStyle(color: AppColors.text, fontSize: 14),
              ),
            ),
            Text(
              context.tr(_languageLabel(language)),
              style: const TextStyle(color: AppColors.textDim, fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textDim, size: 22),
          ],
        ),
      ),
    );
  }

  /// 展示中英文选项，并在选择后持久化用户偏好。
  Future<void> _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    AppLanguage selectedLanguage,
  ) async {
    final nextLanguage = await showDialog<AppLanguage>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xCC000000),
      builder: (dialogContext) =>
          _LanguageSelectionDialog(selectedLanguage: selectedLanguage),
    );
    if (nextLanguage == null) {
      return;
    }
    await ref.read(appLocaleProvider.notifier).setLanguage(nextLanguage);
  }
}

class _LanguageSelectionDialog extends StatelessWidget {
  const _LanguageSelectionDialog({required this.selectedLanguage});

  final AppLanguage selectedLanguage;

  @override
  /// 构建语言选择弹窗，突出当前选中的语言。
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: 343,
          decoration: BoxDecoration(
            color: const Color(0xFF1B2D4D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    const SizedBox(width: 44),
                    Expanded(
                      child: Center(
                        child: Text(
                          context.tr('选择语言'),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: AppFonts.s16,
                            fontWeight: AppFonts.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.cancel_outlined),
                      color: const Color(0xFF7DA2CE),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF233854)),
              _LanguageOption(
                label: '简体中文',
                selected: selectedLanguage == AppLanguage.chinese,
                onTap: () => Navigator.of(context).pop(AppLanguage.chinese),
              ),
              _LanguageOption(
                label: context.tr('English'),
                selected: selectedLanguage == AppLanguage.english,
                onTap: () => Navigator.of(context).pop(AppLanguage.english),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  /// 构建单个语言选项与选中状态。
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: AppFonts.s14,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check, color: AppColors.primaryBright),
            ],
          ),
        ),
      ),
    );
  }
}

String _languageLabel(AppLanguage language) {
  return switch (language) {
    AppLanguage.chinese => '简体中文',
    AppLanguage.english => 'English',
  };
}

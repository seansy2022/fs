import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rc_ui/src/core/app_assets.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class AlertListDialog extends StatelessWidget {
  const AlertListDialog({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    this.width = 343,
    this.onClose,
  });

  final String title;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String> onOptionSelected;
  final double width;
  final VoidCallback? onClose;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<String> options,
    String? selectedOption,
    double width = 343,
    required ValueChanged<String> onOptionSelected,
    VoidCallback? onClose,
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: const Color(0xCC000000),
      builder: (dialogContext) => AlertListDialog(
        title: title,
        options: options,
        selectedOption: selectedOption,
        width: width,
        onOptionSelected: (value) {
          onOptionSelected(value);
          Navigator.of(dialogContext).pop();
        },
        onClose: () {
          onClose?.call();
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = math.min(width, screen.width - 16);
    final maxHeight = screen.height - 80; // top 40 + bottom 40

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: maxHeight,
          ),
          child: Container(
            width: dialogWidth,
            decoration: BoxDecoration(
              color: const Color(0xFF1B2D4D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x66233854), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(title: title, onClose: onClose),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFF233854),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0x33233854),
                    ),
                    itemBuilder: (_, i) {
                      final option = options[i];
                      final selected = option == selectedOption;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onOptionSelected(option),
                        child: SizedBox(
                          height: 44,
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4, // 22.4 / 16
                                  ),
                                ),
                              ),
                              if (selected)
                                Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: SvgPicture.asset(
                                    AppAssets.alertCheck,
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4, // 25.2 / 18
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SvgPicture.asset(
                AppAssets.alertClose,
                width: 24,
                height: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

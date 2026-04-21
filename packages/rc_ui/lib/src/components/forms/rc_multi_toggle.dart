import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class RcMultiToggle<T> extends StatelessWidget {
  const RcMultiToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.width,
    this.height = 24,
    this.fontSize = AppFonts.s12,
    this.keepSingleJoinBorder = false,
  });

  /// 选项列表，可以是简单的 String，也可以是自定义对象（配合 labelBuilder）
  final List<T> options;

  /// 当前选中的对象
  final T selected;

  /// 切换回调
  final ValueChanged<T> onChanged;

  final double? width;
  final double height;
  final double fontSize;
  final bool keepSingleJoinBorder;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? (options.length * 47.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3.5),
      child: Container(
        width: effectiveWidth,
        height: height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: options.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            final isSelected = value == selected;
            final prevSelected = index > 0 && options[index - 1] == selected;
            final nextSelected =
                index < options.length - 1 && options[index + 1] == selected;
            final showLeft = !keepSingleJoinBorder
                ? true
                : (index == 0 || (isSelected && !prevSelected));
            final showRight = !keepSingleJoinBorder
                ? true
                : (index == options.length - 1 || isSelected || !nextSelected);

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(value),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.horizontal(
                      left: index == 0
                          ? const Radius.circular(3.5)
                          : Radius.zero,
                      right: index == options.length - 1
                          ? const Radius.circular(3.5)
                          : Radius.zero,
                    ),
                    color: const Color(0x661B2D4D),
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x0000C6FF), // rgba(0, 198, 255, 0)
                              Color(0x7F00C6FF), // rgba(0, 198, 255, 0.5)
                            ],
                          )
                        : null,
                    border: Border(
                      top: BorderSide(
                        color: isSelected
                            ? const Color(0xFF00C6FF)
                            : const Color(0xFF0072FF),
                        width: 0.5,
                      ),
                      bottom: BorderSide(
                        color: isSelected
                            ? const Color(0xFF00C6FF)
                            : const Color(0xFF0072FF),
                        width: 0.5,
                      ),
                      left: showLeft
                          ? BorderSide(
                              color: isSelected
                                  ? const Color(0xFF00C6FF)
                                  : const Color(0xFF0072FF),
                              width: 0.5,
                            )
                          : BorderSide.none,
                      right: showRight
                          ? BorderSide(
                              color: isSelected
                                  ? const Color(0xFF00C6FF)
                                  : const Color(0xFF0072FF),
                              width: 0.5,
                            )
                          : BorderSide.none,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF00C6FF,
                              ).withValues(alpha: 0.2),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  foregroundDecoration: null,
                  alignment: Alignment.center,
                  child: Text(
                    value is bool
                        ? (index == 0 ? 'OFF' : 'ON')
                        : value.toString().toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF7DA2CE),
                      fontWeight: AppFonts.w700,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

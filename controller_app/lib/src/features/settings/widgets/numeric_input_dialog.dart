import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rc_ui/rc_ui.dart';

class NumericInputDialog extends StatefulWidget {
  const NumericInputDialog({
    super.key,
    required this.title,
    required this.unit,
    required this.initialValue,
  });

  final String title;
  final String unit;
  final String initialValue;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String unit,
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierLabel: 'numeric_input_dialog',
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return NumericInputDialog(
          title: title,
          unit: unit,
          initialValue: initialValue,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 160),
    );
  }

  @override
  State<NumericInputDialog> createState() => _NumericInputDialogState();
}

class _NumericInputDialogState extends State<NumericInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss([String? value]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: SafeArea(
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: SizedBox(
                width: 311,
                height: 125.5,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF002149),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: AppFonts.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 263,
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0x661B2D4D),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF00C6FF),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  autofocus: true,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'),
                                    ),
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 16,
                                    fontWeight: AppFonts.w600,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onSubmitted: _dismiss,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.unit,
                                style: const TextStyle(
                                  color: Color(0xFF465D7A),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

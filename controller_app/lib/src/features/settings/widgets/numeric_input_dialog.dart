import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

import 'numeric_input_field.dart';
import 'numeric_input_value_formatter.dart';

class NumericInputDialog extends StatefulWidget {
  const NumericInputDialog({
    super.key,
    required this.title,
    required this.unit,
    required this.initialValue,
    this.allowSigned = false,
    this.allowDecimal = true,
    this.allowPositive = true,
    this.fixedNegativePrefix = false,
    this.maxAbsValue,
    this.maxLength = 4,
  });

  final String title;
  final String unit;
  final String initialValue;
  final bool allowSigned;
  final bool allowDecimal;
  final bool allowPositive;
  final bool fixedNegativePrefix;
  final num? maxAbsValue;
  final int maxLength;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String unit,
    bool allowSigned = false,
    bool allowDecimal = true,
    bool allowPositive = true,
    bool fixedNegativePrefix = false,
    num? maxAbsValue,
    int maxLength = 4,
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
          allowSigned: allowSigned,
          allowDecimal: allowDecimal,
          allowPositive: allowPositive,
          fixedNegativePrefix: fixedNegativePrefix,
          maxAbsValue: maxAbsValue,
          maxLength: maxLength,
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
    text: widget.fixedNegativePrefix
        ? displayNumericInputValue(
            widget.initialValue,
            fixedNegativePrefix: widget.fixedNegativePrefix,
          )
        : widget.initialValue,
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

  void _submit(String value) {
    _dismiss(
      submitNumericInputValue(
        value,
        fixedNegativePrefix: widget.fixedNegativePrefix,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: SafeArea(
          child: AnimatedPadding(
            key: const ValueKey('numeric-input-dialog-padding'),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
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
                        NumericInputField(
                          controller: _controller,
                          unit: widget.unit,
                          allowSigned: widget.allowSigned,
                          allowDecimal: widget.allowDecimal,
                          allowPositive: widget.allowPositive,
                          fixedNegativePrefix: widget.fixedNegativePrefix,
                          maxAbsValue: widget.maxAbsValue,
                          maxLength: widget.maxLength,
                          onSubmitted: _submit,
                        ),
                      ],
                    ),
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

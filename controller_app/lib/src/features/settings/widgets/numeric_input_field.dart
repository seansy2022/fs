import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rc_ui/rc_ui.dart';

import 'numeric_input_value_formatter.dart';

class NumericInputField extends StatelessWidget {
  const NumericInputField({
    super.key,
    required this.controller,
    required this.unit,
    required this.allowSigned,
    required this.allowDecimal,
    required this.allowPositive,
    required this.fixedNegativePrefix,
    required this.maxAbsValue,
    required this.maxLength,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String unit;
  final bool allowSigned;
  final bool allowDecimal;
  final bool allowPositive;
  final bool fixedNegativePrefix;
  final num? maxAbsValue;
  final int maxLength;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final signedInput = allowSigned && !fixedNegativePrefix;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 263,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0x661B2D4D),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF00C6FF)),
        ),
        child: Row(
          children: [
            if (fixedNegativePrefix) ...[
              const Text(
                '-',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: AppFonts.w600,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(
                  signed: signedInput,
                  decimal: allowDecimal,
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(
                      _allowedInputPattern(
                        allowSigned: signedInput,
                        allowDecimal: allowDecimal,
                      ),
                    ),
                  ),
                  LengthLimitingTextInputFormatter(maxLength),
                  positiveValueGuard(
                    allowPositive: fixedNegativePrefix || allowPositive,
                  ),
                  absoluteValueLimitGuard(maxAbsValue: maxAbsValue),
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
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              unit,
              style: const TextStyle(color: Color(0xFF465D7A), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

String _allowedInputPattern({
  required bool allowSigned,
  required bool allowDecimal,
}) {
  final signs = allowSigned ? r'\-' : '';
  final decimal = allowDecimal ? r'\.' : '';
  return '[$signs${decimal}0-9]';
}

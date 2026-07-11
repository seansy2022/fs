import 'package:flutter/services.dart';

String displayNumericInputValue(
  String value, {
  required bool fixedNegativePrefix,
}) {
  if (!fixedNegativePrefix) {
    return value;
  }
  final parsed = num.tryParse(value.trim());
  if (parsed == null) {
    return value;
  }
  return _compactNumber(parsed.abs());
}

String submitNumericInputValue(
  String value, {
  required bool fixedNegativePrefix,
}) {
  if (!fixedNegativePrefix) {
    return value;
  }
  final text = value.trim();
  if (text.isEmpty) {
    return text;
  }
  final parsed = num.tryParse(text);
  if (parsed == null || parsed == 0) {
    return text;
  }
  return '-${_compactNumber(parsed.abs())}';
}

TextInputFormatter positiveValueGuard({required bool allowPositive}) {
  return TextInputFormatter.withFunction((oldValue, newValue) {
    if (allowPositive) {
      return newValue;
    }
    final text = newValue.text.trim();
    if (text.isEmpty || text == '-' || text == '-.') {
      return newValue;
    }
    final value = num.tryParse(text);
    if (value == null || value <= 0) {
      return newValue;
    }
    return oldValue;
  });
}

TextInputFormatter absoluteValueLimitGuard({required num? maxAbsValue}) {
  return TextInputFormatter.withFunction((oldValue, newValue) {
    if (maxAbsValue == null) {
      return newValue;
    }
    final text = newValue.text.trim();
    if (text.isEmpty || text == '-' || text == '-.') {
      return newValue;
    }
    final value = num.tryParse(text);
    if (value == null || value.abs() <= maxAbsValue) {
      return newValue;
    }
    return oldValue;
  });
}

String _compactNumber(num value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
}

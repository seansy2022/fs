import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

void showSelectionSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selectedOption,
  double? titleFontSize,
  FontWeight? titleFontWeight,
  double? optionFontSize,
  required ValueChanged<String> onOptionSelected,
}) {
  final rootContext = Navigator.of(context, rootNavigator: true).context;
  AlertSelectionSheet.show(
    rootContext,
    title: title,
    options: options,
    selectedOption: selectedOption,
    titleFontSize: titleFontSize,
    titleFontWeight: titleFontWeight,
    optionFontSize: optionFontSize,
    onOptionSelected: onOptionSelected,
  );
}

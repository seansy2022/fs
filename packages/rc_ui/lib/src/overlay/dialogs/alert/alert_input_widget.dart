import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class AlertInputWidget extends StatefulWidget {
  const AlertInputWidget({
    super.key,
    required this.title,
    required this.hintText,
    required this.initialText,
    required this.cancelText,
    required this.confirmText,
    this.maxLength,
  });
  final String title, hintText, initialText, cancelText, confirmText;
  final int? maxLength;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String hintText = '输入提示语',
    String initialText = '',
    String cancelText = '取消',
    String confirmText = '确定',
    bool barrierDismissible = true,
    int? maxLength,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: const Color(0xCC000000),
      builder: (_) => AlertInputWidget(
        title: title,
        hintText: hintText,
        initialText: initialText,
        cancelText: cancelText,
        confirmText: confirmText,
        maxLength: maxLength,
      ),
    );
  }

  @override
  State<AlertInputWidget> createState() => _AlertInputWidgetState();
}

class _AlertInputWidgetState extends State<AlertInputWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode()
      ..addListener(() {
        if (!mounted) return;
        setState(() {});
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    final width = math.min(313.0, MediaQuery.of(context).size.width - 32);
    return Material(
      type: MaterialType.transparency,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + insets.bottom),
        child: Center(
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: const Color(0xFF002149),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xA37DA2CE)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_titleArea(), _inputArea(), _buttonArea()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _titleArea() => Container(
    constraints: const BoxConstraints(minHeight: 70),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Text(
      widget.title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFFEDF5FF),
        fontSize: AppFonts.s16,
        fontWeight: AppFonts.w600,
        height: 1.2,
      ),
    ),
  );

  Widget _inputArea() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
    child: Builder(
      builder: (context) {
        final borderColor = _hasError
            ? const Color(0xFFFF3700)
            : (_focusNode.hasFocus
                  ? const Color(0xFF00C6FF)
                  : const Color(0xFF0072FF));
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0x661B2D4D),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Center(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              cursorColor: const Color(0xFF0072FF),
              cursorWidth: 1,
              cursorHeight: 16,
              cursorRadius: const Radius.circular(1),
              inputFormatters: widget.maxLength == null
                  ? null
                  : [LengthLimitingTextInputFormatter(widget.maxLength)],
              onChanged: (_) {
                if (!_hasError) return;
                setState(() => _hasError = false);
              },
              style: const TextStyle(
                color: Color(0xFFEDF5FF),
                fontSize: AppFonts.s14,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF465D7A),
                  fontSize: AppFonts.s14,
                ),
                isDense: true,
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _buttonArea() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Row(
      children: [
        Expanded(
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Text(
              widget.cancelText,
              style: const TextStyle(
                color: Color(0xFFEDF5FF),
                fontSize: AppFonts.s14,
                fontWeight: AppFonts.w400,
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0x661B2D4D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFF0072FF), width: 1),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: IconButton(
            onPressed: _onConfirm,
            icon: Text(
              widget.confirmText,
              style: const TextStyle(
                color: Color(0xFFEDF5FF),
                fontSize: AppFonts.s14,
                fontWeight: AppFonts.w400,
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0x661B2D4D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFF0072FF), width: 1),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  void _onConfirm() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _hasError = true);
      _focusNode.requestFocus();
      return;
    }
    Navigator.of(context).pop(text);
  }
}

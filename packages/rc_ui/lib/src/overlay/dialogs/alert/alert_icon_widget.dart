import 'dart:math' as math;

import 'package:flutter/material.dart';

class AlertIconWidget extends StatelessWidget {
  const AlertIconWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconAsset,
    this.cancelText,
    this.confirmText = '确定',
    this.onCancel,
    this.onConfirm,
  });

  final String title;
  final String message;
  final Widget? icon;
  final String? iconAsset;

  /// If null, bottom uses a single confirm button.
  final String? cancelText;
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  bool get _hasIcon => icon != null || iconAsset != null;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    Widget? icon,
    String? iconAsset,
    String? cancelText,
    String confirmText = '确定',
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: const Color(0xCC000000),
      builder: (dialogContext) => AlertIconWidget(
        title: title,
        message: message,
        icon: icon,
        iconAsset: iconAsset,
        cancelText: cancelText,
        confirmText: confirmText,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(313.0, MediaQuery.of(context).size.width - 32);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF002149),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xA37DA2CE)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasIcon) _buildTop(),
              _buildMessage(),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTop() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: icon ?? Image.asset(iconAsset!, width: 44, height: 44),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFEDF5FF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    final contentText = _hasIcon
        ? message
        : (message.isNotEmpty ? message : title);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, _hasIcon ? 8 : 24, 16, _hasIcon ? 14 : 24),
      child: Text(
        contentText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFEDF5FF),
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildButtons() {
    if (cancelText == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: SizedBox(
          width: double.infinity,
          child: _ActionButton(text: confirmText, onPressed: onConfirm),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(text: cancelText!, onPressed: onCancel),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(text: confirmText, onPressed: onConfirm),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFEDF5FF),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x661B2D4D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Color(0xFF0072FF), width: 1),
        ),
      ),
    );
  }
}

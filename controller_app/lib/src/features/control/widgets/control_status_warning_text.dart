import 'package:flutter/material.dart';

class ControlStatusWarningText extends StatelessWidget {
  const ControlStatusWarningText({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        color: Color.fromRGBO(255, 55, 0, 1),
      ),
    );
  }
}

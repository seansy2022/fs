import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.onRefresh,
    this.right,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;
  final Widget? right;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TechShell(
        child: Column(
          children: [
            TopAppBar(
              title: title,
              onBack: onBack,
              onRefresh: onRefresh,
              right: right,
            ),
            Expanded(
              child: Padding(padding: padding, child: body),
            ),
          ],
        ),
      ),
    );
  }
}

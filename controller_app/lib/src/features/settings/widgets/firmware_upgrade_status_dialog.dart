import 'dart:async';

import 'package:flutter/material.dart';

import 'firmware_upgrade_status_view.dart';

enum FirmwareUpgradeStatusOutcome { success, failure }

class FirmwareUpgradeStatusDialog extends StatefulWidget {
  const FirmwareUpgradeStatusDialog({
    super.key,
    required this.outcome,
    this.autoCloseOnSuccess = false,
    this.autoCloseDelay = const Duration(seconds: 2),
  });

  final FirmwareUpgradeStatusOutcome outcome;
  final bool autoCloseOnSuccess;
  final Duration autoCloseDelay;

  static Future<void> show(
    BuildContext context, {
    required FirmwareUpgradeStatusOutcome outcome,
    bool autoCloseOnSuccess = false,
    Duration autoCloseDelay = const Duration(seconds: 2),
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FirmwareUpgradeStatusDialog(
        outcome: outcome,
        autoCloseOnSuccess: autoCloseOnSuccess,
        autoCloseDelay: autoCloseDelay,
      ),
    );
  }

  @override
  State<FirmwareUpgradeStatusDialog> createState() =>
      _FirmwareUpgradeStatusDialogState();
}

class _FirmwareUpgradeStatusDialogState
    extends State<FirmwareUpgradeStatusDialog> {
  Timer? _timer;
  Timer? _autoCloseTimer;
  int _progress = 0;
  late FirmwareUpgradeVisualState _visualState =
      FirmwareUpgradeVisualState.loading;

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _startProgress() {
    final target = widget.outcome == FirmwareUpgradeStatusOutcome.success
        ? 100
        : 50;

    _timer = Timer.periodic(const Duration(milliseconds: 36), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_progress >= target) {
        timer.cancel();
        setState(() {
          _visualState = widget.outcome == FirmwareUpgradeStatusOutcome.success
              ? FirmwareUpgradeVisualState.success
              : FirmwareUpgradeVisualState.failure;
        });
        if (widget.outcome == FirmwareUpgradeStatusOutcome.success &&
            widget.autoCloseOnSuccess) {
          _autoCloseTimer = Timer(widget.autoCloseDelay, () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
        return;
      }

      setState(() {
        _progress = (_progress + 5).clamp(0, target);
      });
    });
  }

  void _tryClose() {
    if (_visualState == FirmwareUpgradeVisualState.loading) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: _tryClose,
        child: FirmwareUpgradeStatusView(
          state: _visualState,
          progress: _progress,
        ),
      ),
    );
  }
}

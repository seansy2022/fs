import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../../../core/localization/app_localizations.dart';
import 'firmware_upgrade_status_view.dart';

class FirmwareProgressDialog extends StatefulWidget {
  const FirmwareProgressDialog({super.key, required this.progress});

  final Stream<ReceiverUpgradeProgress> progress;

  @override
  State<FirmwareProgressDialog> createState() => _FirmwareProgressDialogState();
}

class _FirmwareProgressDialogState extends State<FirmwareProgressDialog> {
  StreamSubscription<ReceiverUpgradeProgress>? _sub;
  Timer? _autoCloseTimer;
  FirmwareUpgradeVisualState _state = FirmwareUpgradeVisualState.loading;
  String _failureMessage = '请检查设备状态后再试！';
  int _displayProgress = 0;

  @override
  void initState() {
    super.initState();
    _sub = widget.progress.listen(_onProgress, onDone: _onDone);
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _onProgress(ReceiverUpgradeProgress progress) {
    if (!mounted) return;
    final state = switch (progress.stage) {
      ReceiverUpgradeStage.completed => FirmwareUpgradeVisualState.success,
      ReceiverUpgradeStage.failed => FirmwareUpgradeVisualState.failure,
      _ => FirmwareUpgradeVisualState.loading,
    };
    setState(() {
      _state = state;
      _displayProgress = _progressValue(progress, state);
      if (state == FirmwareUpgradeVisualState.failure) {
        _failureMessage = _messageOf(progress);
      }
    });
    if (state == FirmwareUpgradeVisualState.success) {
      _scheduleAutoClose();
    }
  }

  void _onDone() {
    if (!mounted || _state != FirmwareUpgradeVisualState.loading) return;
    setState(() {
      _state = FirmwareUpgradeVisualState.failure;
      _displayProgress = _displayProgress < 50 ? 50 : _displayProgress;
      _failureMessage = AppText.tr('升级连接已结束，请检查设备状态后重试！');
    });
  }

  int _progressValue(
    ReceiverUpgradeProgress progress,
    FirmwareUpgradeVisualState state,
  ) {
    if (state == FirmwareUpgradeVisualState.success) return 100;
    if (state == FirmwareUpgradeVisualState.failure) {
      return _displayProgress < 50 ? 50 : _displayProgress;
    }
    return switch (progress.stage) {
      ReceiverUpgradeStage.enteringBoot => 10,
      ReceiverUpgradeStage.waitingBootReconnect => 15,
      ReceiverUpgradeStage.sendingLength => 20,
      ReceiverUpgradeStage.sendingPayload =>
        20 + (progress.fraction * 80).round(),
      ReceiverUpgradeStage.completed => 100,
      ReceiverUpgradeStage.failed => _displayProgress,
      ReceiverUpgradeStage.idle => 0,
    };
  }

  String _messageOf(ReceiverUpgradeProgress progress) {
    final raw = progress.message?.trim();
    if (raw == null || raw.isEmpty) {
      return AppText.tr('请检查设备状态后再试！');
    }
    if (raw.contains('Timed out')) {
      return AppText.tr('升级超时，请检查设备连接后重试！');
    }
    return raw;
  }

  void _scheduleAutoClose() {
    _autoCloseTimer ??= Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _tryClose() {
    if (_state == FirmwareUpgradeVisualState.loading) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tryClose,
        child: FirmwareUpgradeStatusView(
          state: _state,
          progress: _displayProgress,
          failureMessage: _failureMessage,
        ),
      ),
    );
  }
}

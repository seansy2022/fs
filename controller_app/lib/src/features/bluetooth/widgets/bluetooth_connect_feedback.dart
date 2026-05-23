import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

enum BluetoothConnectFeedbackResult { success, failure }

Future<BluetoothConnectFeedbackResult> showBluetoothConnectFeedback(
  BuildContext context, {
  required Future<bool> Function() connect,
}) async {
  final notifier = ValueNotifier<_BluetoothConnectStage>(
    _BluetoothConnectStage.connecting,
  );
  final startedAt = DateTime.now();
  final navigator = Navigator.of(context, rootNavigator: true);

  unawaited(
    showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'bluetooth_connect_feedback',
      barrierColor: const Color(0x99000000),
      pageBuilder: (_, __, ___) {
        return PopScope(
          canPop: false,
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: ValueListenableBuilder<_BluetoothConnectStage>(
                valueListenable: notifier,
                builder: (context, stage, _) {
                  return _BluetoothConnectFeedbackDialog(
                    stage: stage,
                    startedAt: startedAt,
                    notifier: notifier,
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );

  await Future<void>.delayed(const Duration(milliseconds: 80));

  try {
    final connected = await connect();
    if (!connected) {
      throw StateError('connect failed');
    }
    notifier.value = _BluetoothConnectStage.completingSuccess;
    await _waitForStage(notifier, _BluetoothConnectStage.success);
    await Future<void>.delayed(const Duration(seconds: 2));
    return BluetoothConnectFeedbackResult.success;
  } catch (_) {
    notifier.value = _BluetoothConnectStage.completingFailure;
    await _waitForStage(notifier, _BluetoothConnectStage.failure);
    await Future<void>.delayed(const Duration(seconds: 2));
    return BluetoothConnectFeedbackResult.failure;
  } finally {
    notifier.dispose();
    if (navigator.mounted && navigator.canPop()) {
      navigator.pop();
    }
  }
}

Future<void> _waitForStage(
  ValueNotifier<_BluetoothConnectStage> notifier,
  _BluetoothConnectStage target,
) async {
  if (notifier.value == target) {
    return;
  }
  final completer = Completer<void>();
  void listener() {
    if (notifier.value == target && !completer.isCompleted) {
      completer.complete();
    }
  }

  notifier.addListener(listener);
  try {
    await completer.future.timeout(
      const Duration(seconds: 1),
      onTimeout: () {},
    );
  } finally {
    notifier.removeListener(listener);
  }
}

enum _BluetoothConnectStage {
  connecting,
  completingSuccess,
  completingFailure,
  success,
  failure,
}

class _BluetoothConnectFeedbackDialog extends StatelessWidget {
  const _BluetoothConnectFeedbackDialog({
    required this.stage,
    required this.startedAt,
    required this.notifier,
  });

  final _BluetoothConnectStage stage;
  final DateTime startedAt;
  final ValueNotifier<_BluetoothConnectStage> notifier;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: switch (stage) {
        _BluetoothConnectStage.connecting => BlueConnectingLoading(
          key: const ValueKey('connecting'),
          text: '\u84dd\u7259\u8fde\u63a5\u4e2d...',
          connectingStartedAt: startedAt,
        ),
        _BluetoothConnectStage.completingSuccess => BlueConnectingLoading(
          key: const ValueKey('completing-success'),
          text: '\u84dd\u7259\u8fde\u63a5\u4e2d...',
          connectingStartedAt: startedAt,
          complete: true,
          onCompleted: () {
            if (notifier.value == _BluetoothConnectStage.completingSuccess) {
              notifier.value = _BluetoothConnectStage.success;
            }
          },
        ),
        _BluetoothConnectStage.completingFailure => BlueConnectingLoading(
          key: const ValueKey('completing-failure'),
          text: '\u84dd\u7259\u8fde\u63a5\u4e2d...',
          connectingStartedAt: startedAt,
          complete: true,
          onCompleted: () {
            if (notifier.value == _BluetoothConnectStage.completingFailure) {
              notifier.value = _BluetoothConnectStage.failure;
            }
          },
        ),
        _BluetoothConnectStage.success => const BlueConnectSuccessLoading(
          key: ValueKey('success'),
          text: '\u8fde\u63a5\u6210\u529f',
          progress: 1,
        ),
        _BluetoothConnectStage.failure => const BlueConnectFailLoading(
          key: ValueKey('failure'),
          text: '\u8fde\u63a5\u5931\u8d25',
          progress: 1,
        ),
      },
    );
  }
}

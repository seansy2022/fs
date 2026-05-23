import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

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

enum _UpgradeVisualState { loading, success, failure }

class _FirmwareUpgradeStatusDialogState
    extends State<FirmwareUpgradeStatusDialog> {
  static const _loadingColor = Color(0xFF00C6FF);
  static const _successColor = Color(0xFF67E600);
  static const _failureColor = Color(0xFFFF3700);
  static const _inactiveColor = Color(0xFF1B2D4D);

  Timer? _timer;
  Timer? _autoCloseTimer;
  int _progress = 0;
  late _UpgradeVisualState _visualState = _UpgradeVisualState.loading;

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
              ? _UpgradeVisualState.success
              : _UpgradeVisualState.failure;
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
        _progress = math.min(_progress + 5, target);
      });
    });
  }

  Color get _activeColor => switch (_visualState) {
    _UpgradeVisualState.loading => _loadingColor,
    _UpgradeVisualState.success => _successColor,
    _UpgradeVisualState.failure => _failureColor,
  };

  double get _dialogHeight =>
      _visualState == _UpgradeVisualState.failure ? 154 : 130;

  void _tryClose() {
    if (_visualState == _UpgradeVisualState.loading) return;
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
        child: SizedBox(
          width: 236,
          height: _dialogHeight,
          child: Column(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(90),
                      painter: _SegmentProgressPainter(
                        progress: _progress / 100,
                        activeColor: _activeColor,
                        inactiveColor: _inactiveColor,
                      ),
                    ),
                    _CenterContent(
                      state: _visualState,
                      progress: _progress,
                      color: _activeColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                switch (_visualState) {
                  _UpgradeVisualState.loading => '固件更新中…',
                  _UpgradeVisualState.success => '固件更新成功！',
                  _UpgradeVisualState.failure => '更新失败！',
                },
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: AppFonts.w600,
                ),
              ),
              if (_visualState == _UpgradeVisualState.failure) ...[
                const SizedBox(height: 8),
                const Text(
                  '请检查设备状态后再试！',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF7DA2CE), fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterContent extends StatelessWidget {
  const _CenterContent({
    required this.state,
    required this.progress,
    required this.color,
  });

  final _UpgradeVisualState state;
  final int progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      _UpgradeVisualState.loading => Text(
        '$progress%',
        style: TextStyle(color: color, fontSize: 16, fontWeight: AppFonts.w600),
      ),
      _UpgradeVisualState.success => Icon(Icons.check, color: color, size: 26),
      _UpgradeVisualState.failure => Icon(Icons.close, color: color, size: 24),
    };
  }
}

class _SegmentProgressPainter extends CustomPainter {
  const _SegmentProgressPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    const segmentCount = 20;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final litCount = (segmentCount * progress).ceil();
    final segmentPath = _buildSegmentPath();
    const segmentScale = 0.5;

    for (var i = 0; i < segmentCount; i++) {
      final angle = -math.pi / 2 + (2 * math.pi / segmentCount) * i;
      final segmentCenter = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final paint = Paint()
        ..color = i < litCount ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(segmentCenter.dx, segmentCenter.dy);
      canvas.rotate(angle + math.pi / 2);
      canvas.scale(segmentScale, segmentScale);
      canvas.drawPath(segmentPath, paint);
      canvas.restore();
    }
  }

  Path _buildSegmentPath() {
    const width = 11.99951171875;
    const height = 19.99951171875;
    final centerX = width / 2;
    final centerY = height / 2;
    return Path()
      ..moveTo(0 - centerX, 0 - centerY)
      ..lineTo(11.9996 - centerX, 0 - centerY)
      ..lineTo(9.99967 - centerX, 19.9993 - centerY)
      ..lineTo(1.99993 - centerX, 19.9993 - centerY)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _SegmentProgressPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        activeColor != oldDelegate.activeColor ||
        inactiveColor != oldDelegate.inactiveColor;
  }
}

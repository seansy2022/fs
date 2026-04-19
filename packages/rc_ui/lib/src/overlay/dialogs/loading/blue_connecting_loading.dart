import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';
import 'blue_loading_base.dart';

class BlueConnectingLoading extends StatefulWidget {
  static const waitingProgress = 0.8;
  static const waitingDuration = Duration(milliseconds: 7000);

  const BlueConnectingLoading({
    super.key,
    this.text = '设备连接中…',
    this.connectingStartedAt,
    this.complete = false,
    this.onCompleted,
  });

  final String text;
  final DateTime? connectingStartedAt;
  final bool complete;
  final VoidCallback? onCompleted;

  static double waitingProgressForStart(
    DateTime? connectingStartedAt, {
    DateTime? now,
  }) {
    if (connectingStartedAt == null) return 0;
    final currentTime = now ?? DateTime.now();
    final elapsedMs = currentTime
        .difference(connectingStartedAt)
        .inMilliseconds;
    final clampedMs = elapsedMs.clamp(0, waitingDuration.inMilliseconds);
    final ratio = clampedMs / waitingDuration.inMilliseconds;
    return (waitingProgress * ratio).clamp(0.0, waitingProgress).toDouble();
  }

  @override
  State<BlueConnectingLoading> createState() => _BlueConnectingLoadingState();
}

class _BlueConnectingLoadingState extends State<BlueConnectingLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completionNotified = false;

  double get _progress => _controller.value.clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
          value: 0,
        )..addListener(() {
          if (mounted) setState(() {});
        });
    if (widget.complete) {
      _animateToComplete();
    } else {
      _animateToWaitingProgress();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BlueConnectingLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.complete != oldWidget.complete) {
      if (widget.complete) {
        _animateToComplete();
      } else {
        _completionNotified = false;
        _animateToWaitingProgress();
      }
      return;
    }
    if (!widget.complete &&
        widget.connectingStartedAt != oldWidget.connectingStartedAt) {
      _animateToWaitingProgress();
    }
  }

  Future<void> _animateToWaitingProgress() async {
    if (!mounted || widget.complete) return;
    final startProgress = _waitingStartProgress();
    _controller.value = startProgress;
    final remaining = BlueConnectingLoading.waitingProgress - startProgress;
    if (remaining <= 0) return;
    final ratio = remaining / BlueConnectingLoading.waitingProgress;
    final durationMs =
        (BlueConnectingLoading.waitingDuration.inMilliseconds * ratio).round();
    await _controller.animateTo(
      BlueConnectingLoading.waitingProgress,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.linear,
    );
  }

  Future<void> _animateToComplete() async {
    if (_controller.value < BlueConnectingLoading.waitingProgress) {
      _controller.value = BlueConnectingLoading.waitingProgress;
    }
    await _controller.animateTo(
      1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    if (_completionNotified) return;
    _completionNotified = true;
    widget.onCompleted?.call();
  }

  double _waitingStartProgress() {
    return BlueConnectingLoading.waitingProgressForStart(
      widget.connectingStartedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).round();
    return BlueLoadingBase(
      text: widget.text,
      middle: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(60),
              painter: _ConnectingRingPainter(progress: _progress),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: Color(0xFF00C6FF),
                fontSize: AppFonts.s14,
                fontWeight: AppFonts.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectingRingPainter extends CustomPainter {
  const _ConnectingRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF1B2D4D);
    canvas.drawCircle(center, radius, base);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF00C6FF);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _ConnectingRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

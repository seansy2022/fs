import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReconnectOverlayView extends StatelessWidget {
  const ReconnectOverlayView({
    super.key,
    required this.title,
    required this.startedAt,
    this.deviceName,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final DateTime startedAt;
  final String? deviceName;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          const ModalBarrier(dismissible: false, color: Color(0xB3000000)),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Color(0xFFEDF5FF),
                  decoration: TextDecoration.none,
                ),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - 48).clamp(
                            0,
                            double.infinity,
                          ),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0x4010203A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0x661A7CFF),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  18,
                                  16,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const _ReconnectLoadingIndicator(),
                                    const SizedBox(height: 12),
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Color(0xFFEDF5FF),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_hasDeviceName) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        deviceName!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFFB8C9E8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                    if (_hasAction) ...[
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: 180,
                                        child: TextButton(
                                          onPressed: onAction,
                                          style: TextButton.styleFrom(
                                            backgroundColor: const Color(
                                              0x661B2D4D,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              side: const BorderSide(
                                                color: Color(0xFF0072FF),
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            minimumSize: const Size(180, 40),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            actionLabel!,
                                            style: const TextStyle(
                                              color: Color(0xFFEDF5FF),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasAction => actionLabel != null && onAction != null;

  bool get _hasDeviceName {
    final value = deviceName?.trim() ?? '';
    return value.isNotEmpty;
  }
}

/// 持续旋转重连加载图标，避免重试间隔触发进度回退。
class _ReconnectLoadingIndicator extends StatefulWidget {
  const _ReconnectLoadingIndicator();

  @override
  State<_ReconnectLoadingIndicator> createState() =>
      _ReconnectLoadingIndicatorState();
}

class _ReconnectLoadingIndicatorState extends State<_ReconnectLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // 重连等待期间持续旋转，不随单次连接超时重置。
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animationController,
      child: SvgPicture.asset(
        'assets/icons/reconnect_loading.svg',
        width: 60,
        height: 60,
        colorFilter: const ColorFilter.mode(Color(0xFFB8C9E8), BlendMode.srcIn),
      ),
    );
  }
}

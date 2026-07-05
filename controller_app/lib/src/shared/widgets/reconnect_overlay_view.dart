import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

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
          const ModalBarrier(
            dismissible: false,
            color: Color(0xB3000000),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x4010203A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x661A7CFF)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BlueConnectingLoading(
                            text: title,
                            connectingStartedAt: startedAt,
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
                                  backgroundColor: const Color(0x661B2D4D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: const BorderSide(
                                      color: Color(0xFF0072FF),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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

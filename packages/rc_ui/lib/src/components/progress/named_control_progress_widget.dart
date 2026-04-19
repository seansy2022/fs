import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

import 'progress_bar.dart';

class NamedControlProgressWidget extends StatelessWidget {
  const NamedControlProgressWidget({
    super.key,
    required this.title,
    required this.status,
    required this.value,
    this.max = 120,
    this.highlightPlus = true,
    this.highlightTrack = true,
    this.showSignedLabels = false,
    this.showUnsignedRange = false,
    this.horizontalPadding = 20,
    this.showBottomBorder = false,
    this.titleFontSize = AppFonts.s14,
    this.statusFontSize = AppFonts.s12,
    this.onMinus,
    this.onPlus,
    this.onRefresh,
  });

  final String title;
  final String status;
  final double value;
  final int max;
  final bool highlightPlus;
  final bool highlightTrack;
  final bool showSignedLabels;
  final bool showUnsignedRange;
  final double horizontalPadding;
  final bool showBottomBorder;
  final double titleFontSize;
  final double statusFontSize;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF001024)).copyWith(
        border: showBottomBorder
            ? const Border(
                bottom: BorderSide(color: Color(0xFF233854), width: 0.6),
              )
            : null,
      ),
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: 0,
        bottom: 0,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: _titleStyle.copyWith(fontSize: titleFontSize),
                    ),
                    if (onRefresh != null) ...[
                      const SizedBox(width: 4),
                      __RefreshIcon(onTap: onRefresh),
                    ],
                  ],
                ),
                Text(
                  status,
                  style: _statusStyle.copyWith(fontSize: statusFontSize),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 37,
            child: ControlProgressBar(
              value: value,
              max: max,
              scale: 0.6,
              onMinus: onMinus,
              onPlus: onPlus,
              highlightPlus: highlightPlus,
              highlightTrack: highlightTrack,
              showSignedLabels: showSignedLabels,
              showUnsignedRange: showUnsignedRange,
            ),
          ),
        ],
      ),
    );
  }
}

class __RefreshIcon extends StatefulWidget {
  const __RefreshIcon({required this.onTap});
  final VoidCallback? onTap;

  @override
  State<__RefreshIcon> createState() => __RefreshIconState();
}

class __RefreshIconState extends State<__RefreshIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _isPressed ? const Color(0x3300C6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            LucideIcons.refreshCw,
            color: _isPressed ? const Color(0xFF00C6FF) : AppColors.text,
            size: AppDimens.compactIcon(AppDimens.iconM) + 2,
          ),
        ),
      ),
    );
  }
}

const _titleStyle = TextStyle(
  color: Colors.white,
  fontSize: AppFonts.s16,
  fontFamily: AppFonts.roboto,
  height: 1,
);

const _statusStyle = TextStyle(
  color: Color(0xFF00C6FF),
  fontSize: AppFonts.s16,
  fontFamily: AppFonts.roboto,
  height: 1,
);

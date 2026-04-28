import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';
import 'package:rc_ui/src/elements/button/rc_icon_button.dart';

import 'item_button/item_button.dart';
import 'progress_bar.dart';

class SidesControlProgressWidget extends StatefulWidget {
  const SidesControlProgressWidget({
    super.key,
    required this.title,
    required this.leftStatus,
    required this.rightStatus,
    required this.leftValue,
    required this.rightValue,
    this.max = 120,
    this.initialLeftSelected = true,
    this.leftSelected,
    this.titleLeading = false,
    this.statusButtonWidth = 60,
    this.statusFontSize = AppFonts.s12,
    this.titleFontSize = AppFonts.s14,
    this.statusButtonType = RCIconButtonType.normal,
    this.horizontalPadding = 16,
    this.showBottomBorder = true,
    this.onAdjust,
    this.onSelectedChanged,
    this.onRefresh,
  });

  final String title;
  final String leftStatus;
  final String rightStatus;
  final int leftValue;
  final int rightValue;
  final int max;
  final bool initialLeftSelected;
  final bool? leftSelected;
  final bool titleLeading;
  final double statusButtonWidth;
  final double statusFontSize;
  final double titleFontSize;
  final RCIconButtonType statusButtonType;
  final double horizontalPadding;
  final bool showBottomBorder;
  final void Function(bool leftSelected, int delta)? onAdjust;
  final ValueChanged<bool>? onSelectedChanged;
  final VoidCallback? onRefresh;

  @override
  State<SidesControlProgressWidget> createState() =>
      _SidesControlProgressWidgetState();
}

class _SidesControlProgressWidgetState
    extends State<SidesControlProgressWidget> {
  late bool _leftSelected;

  @override
  void initState() {
    super.initState();
    _leftSelected = widget.leftSelected ?? widget.initialLeftSelected;
  }

  @override
  void didUpdateWidget(covariant SidesControlProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leftSelected != null) {
      _leftSelected = widget.leftSelected!;
      return;
    }
    if (oldWidget.initialLeftSelected != widget.initialLeftSelected) {
      _leftSelected = widget.initialLeftSelected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF001024),
        border: widget.showBottomBorder
            ? const Border(
                bottom: BorderSide(color: Color(0xFF233854), width: 0.6),
              )
            : null,
      ),
      padding: EdgeInsets.only(
        left: widget.horizontalPadding,
        right: widget.horizontalPadding,
        top: 12,
        bottom: 12,
      ),
      child: Column(
        children: [_header(), const SizedBox(height: 4), _progressBar()],
      ),
    );
  }

  Widget _header() {
    if (widget.titleLeading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _centerTitle(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statusButton(left: true, compact: true),
              const SizedBox(width: 8),
              _statusButton(left: false, compact: true),
            ],
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _statusButton(left: true, compact: false),
        _centerTitle(),
        _statusButton(left: false, compact: false),
      ],
    );
  }

  Widget _centerTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: _titleStyle()),
        if (widget.onRefresh != null) ...[
          const SizedBox(width: 4),
          _refreshButton(),
        ],
      ],
    );
  }

  Widget _refreshButton() {
    return _RefreshIcon(onTap: widget.onRefresh);
  }

  Widget _statusButton({required bool left, required bool compact}) {
    final button = ItemButton(
      text: left ? widget.leftStatus : widget.rightStatus,
      selected: left ? _leftSelected : !_leftSelected,
      width: widget.statusButtonWidth,
      height: 28,
      fontSize: widget.statusFontSize,
      type: widget.statusButtonType,
      onTap: () => _setSelected(left: left),
    );
    if (compact) return button;
    return Align(
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: button,
    );
  }

  Widget _progressBar() {
    return SizedBox(
      height: 37,
      child: ControlProgressBar(
        value: _selectedValue(),
        leftValue: widget.leftValue,
        rightValue: widget.rightValue,
        max: widget.max,
        scale: 0.5,
        onMinus: () => widget.onAdjust?.call(_leftSelected, -1),
        onPlus: () => widget.onAdjust?.call(_leftSelected, 1),
      ),
    );
  }

  void _setSelected({required bool left}) {
    if (_leftSelected == left) return;
    setState(() => _leftSelected = left);
    widget.onSelectedChanged?.call(left);
  }

  double _selectedValue() {
    if (_leftSelected) return -widget.leftValue.toDouble();
    return widget.rightValue.toDouble();
  }

  TextStyle _titleStyle() {
    return TextStyle(
      color: Colors.white,
      fontSize: widget.titleFontSize,
      fontFamily: AppFonts.roboto,
      height: 1,
    );
  }
}

class _RefreshIcon extends StatefulWidget {
  const _RefreshIcon({required this.onTap});
  final VoidCallback? onTap;

  @override
  State<_RefreshIcon> createState() => _RefreshIconState();
}

class _RefreshIconState extends State<_RefreshIcon> {
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

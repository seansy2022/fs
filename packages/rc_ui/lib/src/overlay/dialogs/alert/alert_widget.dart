
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class AlertSelectionSheet extends StatelessWidget {
  const AlertSelectionSheet({
    super.key,
    required this.title,
    required this.options,
    this.selectedOption,
    this.titleFontSize,
    this.titleFontWeight,
    this.optionFontSize,
    required this.onOptionSelected,
    required this.onClose,
  });

  final String title;
  final List<String> options;
  final String? selectedOption;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final double? optionFontSize;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback onClose;

  static void show(
    BuildContext context, {
    required String title,
    required List<String> options,
    String? selectedOption,
    double? titleFontSize,
    FontWeight? titleFontWeight,
    double? optionFontSize,
    required ValueChanged<String> onOptionSelected,
  }) {
    const headerHeight = 44.0;
    const dividerHeight = 1.0;
    const itemHeight = 44.0;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final contentHeight =
        headerHeight + dividerHeight + options.length * itemHeight;
    final sheetHeight = (contentHeight + safeBottom)
        .clamp(0.0, maxHeight)
        .toDouble();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SizedBox(
          height: sheetHeight,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1B2D4D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 28,
                  offset: Offset(0, -16),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.only(bottom: safeBottom),
              child: _AlertContent(
                title: title,
                options: options,
                selectedOption: selectedOption,
                titleFontSize: titleFontSize,
                titleFontWeight: titleFontWeight,
                optionFontSize: optionFontSize,
                onOptionSelected: onOptionSelected,
                onClose: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _AlertContent extends StatefulWidget {
  const _AlertContent({
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.titleFontSize,
    required this.titleFontWeight,
    required this.optionFontSize,
    required this.onOptionSelected,
    required this.onClose,
  });

  final String title;
  final List<String> options;
  final String? selectedOption;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final double? optionFontSize;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback onClose;

  @override
  State<_AlertContent> createState() => _AlertContentState();
}

class _AlertContentState extends State<_AlertContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(
          widget.title,
          widget.titleFontSize,
          widget.titleFontWeight,
        ),
        _buildDivider(),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: widget.options.length,
              itemBuilder: (context, index) {
                final option = widget.options[index];
                final isSelected = widget.selectedOption == option;
                return _buildOptionItem(option, isSelected);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    String title,
    double? titleFontSize,
    FontWeight? titleFontWeight,
  ) {
    return Container(
      height: 44,
      color: const Color(0xFF1B2D4D),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize ?? AppFonts.s14,
                  fontWeight: titleFontWeight,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _CloseButton(onClose: widget.onClose),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: const Color(0xFF233854));
  }

  Widget _buildOptionItem(String option, bool isSelected) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.onOptionSelected(option);
        widget.onClose();
      },
      child: Container(
        height: 44,
        color: const Color(0xFF1B2D4D),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: widget.optionFontSize ?? AppFonts.s14,
                    color: AppColors.text,
                    fontFamily: option.startsWith('CH') ? 'Roboto' : null,
                  ),
                ),
              ),
            ),
            if (isSelected)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: _CheckIcon(),
                ),
              ),
            Positioned(left: 0, right: 0, bottom: 0, child: _buildDivider()),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: const SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Icon(Icons.cancel, size: 18, color: Color(0xFF7DA2CE)),
        ),
      ),
    );
  }
}

class _CheckIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16.5,
      height: 11,
      child: CustomPaint(painter: _CheckIconPainter()),
    );
  }
}

class _CheckIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C6FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, 5.5)
      ..lineTo(5.5, 11)
      ..lineTo(16.5, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

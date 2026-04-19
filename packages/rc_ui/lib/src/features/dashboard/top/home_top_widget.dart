import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:rc_ui/src/core/app_assets.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class HomeTopWidget extends StatelessWidget {
  const HomeTopWidget({
    super.key,
    required this.isConnected,
    required this.deviceName,
    this.scale = 1,
  });
  static const _designWidth = 686.0;
  static const _designHeight = 240.0;
  static const _connectedAsset = AppAssets.homeTopConnected;
  static const _disconnectedAsset = AppAssets.homeTopDisconnected;
  static const _connectedImage = AppAssets.homeTopConnectedImage;
  final bool isConnected;
  final String deviceName;
  final double scale;
  String get _nameText => isConnected ? deviceName : '--';
  String get _statusText => isConnected ? '设备已连接' : '设备未连接';
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width * scale;
        final boundedWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : screenWidth;
        final width = screenWidth.clamp(0.0, boundedWidth);
        final ratio = width / _designWidth;
        final height = _designHeight * ratio;
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SvgPicture.asset(
                isConnected ? _connectedAsset : _disconnectedAsset,
                fit: BoxFit.cover,
              ),
              if (isConnected)
                Positioned(
                  left: (width * 0.75) - (109 * ratio),
                  top: 20 * ratio,
                  child: _DevicePreview(scale: ratio),
                ),
              Positioned(
                left: 40 * ratio,
                top: 60 * ratio,
                child: _nameLabel(_nameMaxWidth(width, ratio)),
              ),
              Positioned(
                left: 40 * ratio,
                top: 115 * ratio,
                child: _statusLabel(ratio),
              ),
            ],
          ),
        );
      },
    );
  }

  double _nameMaxWidth(double width, double ratio) {
    final leftPadding = 40 * ratio;
    double available;
    if (isConnected) {
      final previewLeftEdge = (width * 0.75) - (109 * ratio);
      available = previewLeftEdge - (16 * ratio) - leftPadding;
    } else {
      available = width - leftPadding - (40 * ratio);
    }
    return available > 0 ? available : 120 * ratio;
  }

  Widget _nameLabel(double maxWidth) {
    return SizedBox(
      width: maxWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          _nameText,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppTextStyles.homeTopName(),
        ),
      ),
    );
  }

  Widget _statusLabel(double ratio) {
    return Text(
      _statusText,
      style: AppTextStyles.homeTopStatus(isConnected: isConnected),
    );
  }
}

class _DevicePreview extends StatelessWidget {
  const _DevicePreview({required this.scale});
  final double scale;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * scale),
      child: SizedBox(
        width: 218 * scale,
        height: 220 * scale,
        child: Image.asset(
          HomeTopWidget._connectedImage,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}

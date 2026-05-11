import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rc_ui/rc_ui.dart';

bool _isMobilePlatform() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

Future<List<Permission>> permissionsForPlatform() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return [Permission.locationWhenInUse, Permission.bluetooth];
  }
  return const [];
}

Future<bool> hasBluetoothPermissions() async {
  if (!_isMobilePlatform()) return true;
  final permissions = await permissionsForPlatform();
  if (permissions.isEmpty) return true;
  final statuses = await Future.wait(
    permissions.map((permission) => permission.status),
  );
  return statuses.every((status) => status.isGranted || status.isLimited);
}

Future<bool> requestBluetoothPermissions(BuildContext context) async {
  if (!_isMobilePlatform()) return true;
  final permissions = await permissionsForPlatform();
  final result = await permissions.request();
  final hasDenied = result.values.any((status) => !status.isGranted);

  if (!hasDenied) return true;
  if (!context.mounted) return false;

  final tip = defaultTargetPlatform == TargetPlatform.iOS
      ? '需要定位和蓝牙权限以扫描并连接蓝牙设备。'
      : '需要蓝牙和定位权限以扫描并连接蓝牙设备。';

  final shouldGoSettings = await AlertIconWidget.show(
    context,
    title: '权限未授予',
    message: tip,
    cancelText: '以后再说',
    confirmText: '去设置',
  );

  if (shouldGoSettings == true) {
    await openAppSettings();
  }
  return false;
}

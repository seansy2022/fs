import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
    ];
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return [Permission.locationWhenInUse, Permission.bluetooth];
  }
  return const [];
}

Future<bool> hasStartupPermissions() async {
  if (!_isMobilePlatform()) return true;
  final permissions = await permissionsForPlatform();
  if (permissions.isEmpty) return true;
  final statuses = await Future.wait(
    permissions.map((permission) => permission.status),
  );
  return statuses.every((status) => status.isGranted || status.isLimited);
}

Future<void> requestStartupPermissions(BuildContext context) async {
  if (!_isMobilePlatform()) return;
  final permissions = await permissionsForPlatform();
  final result = await permissions.request();
  final hasDenied = result.values.any((status) => !status.isGranted);
  if (!hasDenied || !context.mounted) return;
  final tip = defaultTargetPlatform == TargetPlatform.iOS
      ? '请在系统设置中开启定位和蓝牙权限后再使用。'
      : '请在系统设置中开启蓝牙相关权限后再使用。';
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('权限未开启'),
      content: Text(tip),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('稍后'),
        ),
        TextButton(
          onPressed: () async {
            await openAppSettings();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('去开启'),
        ),
      ],
    ),
  );
}

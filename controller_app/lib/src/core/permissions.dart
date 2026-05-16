import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

Future<bool> hasBluetoothPermissions() async {
  final permissions = _bluetoothPermissionsForPlatform();
  for (final permission in permissions) {
    final status = await permission.status;
    if (!status.isGranted) {
      return false;
    }
  }
  return true;
}

Future<bool> requestOrNavigateBluetoothPermission() async {
  final permissions = _bluetoothPermissionsForPlatform();
  final results = await permissions.request();
  final granted = results.values.every((status) => status.isGranted);
  if (granted) {
    return true;
  }
  await openAppSettingsForBluetoothPermission();
  return false;
}

Future<void> openBluetoothSettings(ReceiverRepository repository) async {
  try {
    await repository.turnOnAdapter();
  } catch (_) {
    // Ignore and let caller show user-facing guidance.
  }
}

Future<void> openAppSettingsForBluetoothPermission() async {
  await openAppSettings();
}

List<Permission> _bluetoothPermissionsForPlatform() {
  if (Platform.isAndroid) {
    return <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];
  }
  if (Platform.isIOS) {
    return <Permission>[
      Permission.bluetooth,
    ];
  }
  return <Permission>[];
}

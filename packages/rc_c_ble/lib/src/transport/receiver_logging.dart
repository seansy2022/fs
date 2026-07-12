class ReceiverLogging {
  static const bool linkEnabled = bool.fromEnvironment(
    'RC_LINK_LOG',
    defaultValue: !bool.fromEnvironment('dart.vm.product'),
  );

  static const bool controlEnabled = bool.fromEnvironment(
    'RC_CONTROL_LOG',
    defaultValue: false,
  );

  static const bool upgradeEnabled = bool.fromEnvironment(
    'RC_UPGRADE_LOG',
    defaultValue: false,
  );

  static void link(String message, {String scope = 'Link'}) {
    if (!linkEnabled) {
      return;
    }
    // ignore: avoid_print
    print('[$scope] $message');
  }

  static void phone(String message, {String scope = 'Link'}) {
    link('📱 $message', scope: scope);
  }

  static void device(String message, {String scope = 'Link'}) {
    link('🚗 $message', scope: scope);
  }

  /// 仅在真机升级排查时打印协议帧，避免正常调试产生大量分包日志。
  static void upgradePhone(String message, {String scope = 'Link'}) {
    if (!upgradeEnabled) {
      return;
    }
    phone(message, scope: scope);
  }

  /// 仅在真机升级排查时打印硬件返回的升级协议帧。
  static void upgradeDevice(String message, {String scope = 'Link'}) {
    if (!upgradeEnabled) {
      return;
    }
    device(message, scope: scope);
  }

  /// 打印手机端发送的完整蓝牙字节数据。
  static void transmittedBytes(Iterable<int> bytes, {String scope = 'Link'}) {
    final values = bytes.toList(growable: false);
    phone('tx bytes(${values.length}) ${hexBytes(values)}', scope: scope);
  }

  static String hexBytes(Iterable<int> bytes) {
    return bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }
}

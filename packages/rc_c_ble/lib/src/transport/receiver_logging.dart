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

  /// 正常升级流程不跳过 0x12；仅测试或显式注入时才可开启跳过逻辑。
  static const bool skipBootUpgradeForDebug = false;

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

  /// 打印接收机主动上报或应答的协议帧，便于与手机发送日志区分。
  static void receiver(String message, {String scope = 'Link'}) {
    link('🚢 $message', scope: scope);
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

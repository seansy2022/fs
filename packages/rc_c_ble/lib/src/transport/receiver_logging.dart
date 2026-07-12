class ReceiverLogging {
  static const bool linkEnabled = bool.fromEnvironment(
    'RC_LINK_LOG',
    defaultValue: !bool.fromEnvironment('dart.vm.product'),
  );

  static const bool controlEnabled = bool.fromEnvironment(
    'RC_CONTROL_LOG',
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

class ReceiverLogging {
  static const bool linkEnabled = bool.fromEnvironment(
    'RC_LINK_LOG',
    defaultValue: !bool.fromEnvironment('dart.vm.product'),
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

  static String hexBytes(Iterable<int> bytes) {
    return bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }
}

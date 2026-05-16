class ReceiverLogging {
  static const bool linkEnabled = bool.fromEnvironment(
    'RC_LINK_LOG',
    defaultValue: true,
  );

  static void link(String message, {String scope = 'Link'}) {
    if (!linkEnabled) {
      return;
    }
    // ignore: avoid_print
    print('[$scope] $message');
  }
}

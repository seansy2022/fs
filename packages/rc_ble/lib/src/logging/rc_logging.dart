class RcLogging {
  static const bool linkEnabled = bool.fromEnvironment(
    'RC_LINK_LOG',
    defaultValue: true,
  );

  static const bool protocolEnabled = bool.fromEnvironment(
    'RC_PROTOCOL_LOG',
    defaultValue: true,
  );

  static void link(String message, {String scope = 'Link'}) {
    if (!linkEnabled) return;
    _emit(scope, message);
  }

  static void protocol(String message, {String scope = 'Protocol'}) {
    if (!protocolEnabled) return;
    _emit(scope, message);
  }

  static String hex(List<int> bytes, {int maxBytes = 24}) {
    if (bytes.isEmpty) return '(empty)';
    final limit = bytes.length > maxBytes ? maxBytes : bytes.length;
    final value = bytes
        .take(limit)
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
    if (bytes.length <= limit) return value;
    return '$value ...(+${bytes.length - limit})';
  }

  static void _emit(String scope, String message) {
    // ignore: avoid_print
    print('[$scope] $message');
  }
}

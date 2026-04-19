import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _platformChannel = MethodChannel('rc_configurator_flutter/platform');

Future<int?> androidSdkInt() async {
  if (kIsWeb || !Platform.isAndroid) return null;
  try {
    return await _platformChannel.invokeMethod<int>('androidSdkInt');
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}

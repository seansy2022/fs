import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ble/rc_ble.dart';

import '../protocol/protocol_adapter.dart';
import '../protocol/protocol_adapter_v1.dart';

enum LinkRuntimeMode { ble, mock, usb }

LinkRuntimeMode parseLinkRuntimeMode(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'mock':
      return LinkRuntimeMode.mock;
    case 'usb':
      return LinkRuntimeMode.usb;
    case 'bluetooth':
    case 'ble':
    default:
      return LinkRuntimeMode.ble;
  }
}

final linkRuntimeModeProvider = Provider<LinkRuntimeMode>((ref) {
  const raw = String.fromEnvironment('RC_LINK_MODE', defaultValue: 'ble');
  return parseLinkRuntimeMode(raw);
});

final linkTransportProvider = Provider<LinkTransport>((ref) {
  final mode = ref.watch(linkRuntimeModeProvider);
  RcLogging.link('link mode=$mode', scope: 'LinkProviders');
  final transport = switch (mode) {
    LinkRuntimeMode.mock => MockProtocolLinkTransport(),
    LinkRuntimeMode.usb => UnsupportedUsbTransport(),
    LinkRuntimeMode.ble => FlutterBlueTransport(),
  };
  if (transport is MockProtocolLinkTransport) {
    ref.onDispose(() => transport.dispose());
  }
  return transport;
});

final protocolAdapterProvider = Provider<ProtocolAdapter>((ref) {
  return ProtocolAdapterV1();
});

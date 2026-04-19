import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  test('parseLinkRuntimeMode supports ble/mock/usb', () {
    expect(parseLinkRuntimeMode('ble'), LinkRuntimeMode.ble);
    expect(parseLinkRuntimeMode('bluetooth'), LinkRuntimeMode.ble);
    expect(parseLinkRuntimeMode('mock'), LinkRuntimeMode.mock);
    expect(parseLinkRuntimeMode('usb'), LinkRuntimeMode.usb);
    expect(parseLinkRuntimeMode('unknown'), LinkRuntimeMode.ble);
  });

  test('linkTransportProvider uses mock transport when mode is mock', () {
    final container = ProviderContainer(
      overrides: [
        linkRuntimeModeProvider.overrideWithValue(LinkRuntimeMode.mock),
      ],
    );
    addTearDown(container.dispose);

    final transport = container.read(linkTransportProvider);
    expect(transport, isA<MockProtocolLinkTransport>());
  });
}

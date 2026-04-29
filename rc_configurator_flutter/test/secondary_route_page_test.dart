import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ble/rc_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/page/secondary/secondary_route_page.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_provider.dart';
import 'package:rc_configurator_flutter/src/types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('control mapping page enter resets to CH11 after first frame', (
    tester,
  ) async {
    final transport = MemoryLinkTransport(linkType: LinkType.usb);
    final container = ProviderContainer(
      overrides: [linkTransportProvider.overrideWithValue(transport)],
    );
    addTearDown(() async {
      await transport.dispose();
      container.dispose();
    });
    final notifier = container.read(rcAppStateProvider.notifier);
    final state = RcAppState.initial();
    final ch11 = state.controlMapping.copyWith(channel: 'CH11');
    final ch5 = state.controlMapping.copyWith(channel: 'CH5');
    notifier.state = state.copyWith(
      controlMapping: ch5,
      controlMappings: {'CH11': ch11, 'CH5': ch5},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SecondaryRoutePage(screen: Screen.controlMapping),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(container.read(rcAppStateProvider).controlMapping.channel, 'CH11');
  });
}

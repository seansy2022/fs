import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ble/rc_ble.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_provider.dart';
import 'package:rc_configurator_flutter/src/provider/control_mapping_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('all channels normalize invalid type', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);
    const channels = <String>['CH3', 'CH5', 'CH6', 'CH9', 'CH10'];
    for (final channel in channels) {
      final expectedType = controlTypeOptionsForChannel(channel).first;
      final legacy = notifier.state.controlMapping.copyWith(
        channel: channel,
        type: 'legacy_invalid',
        selectedState: 'legacy_invalid',
        availableStates: const <String>['legacy_invalid'],
      );
      notifier.dispatch(ControlMappingPreviewIntent(legacy));
      final next = container.read(rcAppStateProvider).controlMapping;
      expect(next.channel, channel);
      expect(next.type, expectedType);
      expect(next.selectedState, expectedType);
      expect(next.availableStates.contains('legacy_invalid'), isFalse);
    }
  });
}

ProviderContainer _createContainer() {
  return ProviderContainer(
    overrides: [
      linkTransportProvider.overrideWithValue(
        MemoryLinkTransport(linkType: LinkType.usb),
      ),
    ],
  );
}

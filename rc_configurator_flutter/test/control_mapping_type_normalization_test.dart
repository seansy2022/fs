import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ble/rc_ble.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('all channels normalize invalid type', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);
    const cases = <(String, String)>[
      ('CH3', '单击'),
      ('CH5', '旋钮'),
      ('CH6', '1档'),
      ('CH9', '旋钮'),
      ('CH10', '单击'),
    ];
    for (final c in cases) {
      final legacy = notifier.state.controlMapping.copyWith(
        channel: c.$1,
        type: '无',
        selectedState: '无',
        availableStates: const <String>['无'],
      );
      notifier.dispatch(ControlMappingPreviewIntent(legacy));
      final next = container.read(rcAppStateProvider).controlMapping;
      expect(next.channel, c.$1);
      expect(next.type, c.$2);
      expect(next.selectedState, c.$2);
      expect(next.availableStates.contains('无'), isFalse);
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

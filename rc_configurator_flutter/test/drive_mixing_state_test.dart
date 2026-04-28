import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ble/rc_ble.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_provider.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/types.dart';

void main() {
  test('rear-selected drive ratio writes rear only', () {
    final container = _container();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);

    notifier.dispatch(
      const MixingSettingsUpdatedIntent(
        MixingSettings(
          activeMode: 'DRIVE',
          enabled: true,
          ratio: 28,
          curve: 0,
          direction: 'MIXED',
          selectedChannel: 'CH6',
        ),
      ),
    );

    final drive = container.read(rcAppStateProvider).protocol.driveMixing;
    expect(drive.channel, 5);
    expect(drive.frontRatio, 100);
    expect(drive.rearRatio, 72);
    expect(drive.mode, 1);
  });

  test('front-selected drive ratio writes front only', () {
    final container = _container();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);

    notifier.dispatch(
      const MixingSettingsUpdatedIntent(
        MixingSettings(
          activeMode: 'DRIVE',
          enabled: true,
          ratio: -36,
          curve: 0,
          direction: 'FRONT',
          selectedChannel: 'CH7',
          driveRatioSelectedSide: 'F',
        ),
      ),
    );

    final drive = container.read(rcAppStateProvider).protocol.driveMixing;
    expect(drive.channel, 6);
    expect(drive.frontRatio, 64);
    expect(drive.rearRatio, 100);
    expect(drive.mode, 2);
  });

  test('switching side at ratio zero keeps both ratios at 100', () {
    final container = _container();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);

    notifier.dispatch(
      const MixingSettingsUpdatedIntent(
        MixingSettings(
          activeMode: 'DRIVE',
          enabled: true,
          ratio: 0,
          curve: 0,
          direction: 'REAR',
          selectedChannel: 'CH3',
          driveRatioSelectedSide: 'F',
        ),
      ),
    );

    final drive = container.read(rcAppStateProvider).protocol.driveMixing;
    expect(drive.frontRatio, 100);
    expect(drive.rearRatio, 100);
    expect(drive.mode, 0);
  });
}

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      linkTransportProvider.overrideWithValue(
        MemoryLinkTransport(linkType: LinkType.usb),
      ),
    ],
  );
}

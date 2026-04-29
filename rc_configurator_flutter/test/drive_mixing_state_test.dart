import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ble/rc_ble.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_provider.dart';
import 'package:rc_configurator_flutter/src/types.dart';

void main() {
  test('rear-focused drive ratios write independently', () {
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
          direction: 'MIXED',
          selectedChannel: 'CH6',
          driveFrontRatio: 88,
          driveRearRatio: 72,
          driveFocusedSide: 'R',
        ),
      ),
    );

    final state = container.read(rcAppStateProvider);
    final drive = state.protocol.driveMixing;
    expect(drive.channel, 5);
    expect(drive.frontRatio, 88);
    expect(drive.rearRatio, 72);
    expect(drive.mode, 1);
    expect(state.mixingSettings.driveFrontRatio, 88);
    expect(state.mixingSettings.driveRearRatio, 72);
    expect(state.mixingSettings.driveFocusedSide, 'R');
  });

  test('front-focused drive ratios write independently', () {
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
          direction: 'FRONT',
          selectedChannel: 'CH7',
          driveFrontRatio: 64,
          driveRearRatio: 83,
          driveFocusedSide: 'F',
        ),
      ),
    );

    final state = container.read(rcAppStateProvider);
    final drive = state.protocol.driveMixing;
    expect(drive.channel, 6);
    expect(drive.frontRatio, 64);
    expect(drive.rearRatio, 83);
    expect(drive.mode, 2);
    expect(state.mixingSettings.driveFrontRatio, 64);
    expect(state.mixingSettings.driveRearRatio, 83);
    expect(state.mixingSettings.driveFocusedSide, 'F');
  });

  test('drive ratios can both stay at 100', () {
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
          driveFrontRatio: 100,
          driveRearRatio: 100,
          driveFocusedSide: 'F',
        ),
      ),
    );

    final state = container.read(rcAppStateProvider);
    final drive = state.protocol.driveMixing;
    expect(drive.frontRatio, 100);
    expect(drive.rearRatio, 100);
    expect(state.mixingSettings.driveFocusedSide, 'F');
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

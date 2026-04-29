import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_provider.dart';
import 'package:rc_configurator_flutter/src/types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('brake mixing reset uses off/ch3/ratio100/curve0', () async {
    final container = _container();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);
    notifier.state = RcAppState.initial().copyWith(
      mixingSettings: const MixingSettings(
        activeMode: 'BRAKE',
        enabled: true,
        ratio: 24,
        curve: -31,
        direction: '',
        selectedChannel: 'CH8',
      ),
    );

    await notifier.resetDefaultsForScreen(Screen.mixing);
    final next = container.read(rcAppStateProvider);
    expect(next.protocol.brakeMixing.enabled, isFalse);
    expect(next.protocol.brakeMixing.channel, 2);
    expect(next.protocol.brakeMixing.ratio, 100);
    expect(next.protocol.brakeMixing.curve, 0);
    expect(next.mixingSettings.selectedChannel, 'CH3');
    expect(next.mixingSettings.ratio, 100);
    expect(next.mixingSettings.curve, 0);
  });

  test('brake mixing ratio is clamped to 0..100', () {
    final container = _container();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);

    notifier.dispatch(
      const MixingSettingsUpdatedIntent(
        MixingSettings(
          activeMode: 'BRAKE',
          enabled: false,
          ratio: -20,
          curve: 0,
          direction: '',
          selectedChannel: 'CH3',
        ),
      ),
    );
    expect(container.read(rcAppStateProvider).protocol.brakeMixing.ratio, 0);

    notifier.dispatch(
      const MixingSettingsUpdatedIntent(
        MixingSettings(
          activeMode: 'BRAKE',
          enabled: false,
          ratio: 120,
          curve: 0,
          direction: '',
          selectedChannel: 'CH3',
        ),
      ),
    );
    expect(container.read(rcAppStateProvider).protocol.brakeMixing.ratio, 100);
  });

  test('drive mixing reset uses off/ch3/f100/r100', () async {
    final container = _container();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);
    notifier.state = RcAppState.initial().copyWith(
      mixingSettings: const MixingSettings(
        activeMode: 'DRIVE',
        enabled: true,
        ratio: 45,
        curve: 0,
        direction: 'REAR',
        selectedChannel: 'CH9',
      ),
    );

    await notifier.resetDefaultsForScreen(Screen.mixing);
    final next = container.read(rcAppStateProvider);
    expect(next.protocol.driveMixing.enabled, isFalse);
    expect(next.protocol.driveMixing.channel, 2);
    expect(next.protocol.driveMixing.frontRatio, 100);
    expect(next.protocol.driveMixing.rearRatio, 100);
    expect(next.mixingSettings.selectedChannel, 'CH3');
    expect(next.mixingSettings.driveFrontRatio, 100);
    expect(next.mixingSettings.driveRearRatio, 100);
    expect(next.mixingSettings.driveFocusedSide, 'R');
  });

  test('mixing nav reset resets all four modules', () async {
    final container = _container();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);
    notifier.state = RcAppState.initial().copyWith(
      mixingSettings: const MixingSettings(
        activeMode: 'BRAKE',
        enabled: true,
        ratio: 12,
        curve: -20,
        direction: '',
        selectedChannel: 'CH9',
      ),
      protocol: const RcProtocolState(
        rawPayloadByCommand: <int, List<int>>{},
        curveValues: <int>[0, 0, 0],
        fourWheelSteer: FourWheelSteerSnapshot(
          enabled: true,
          channel: 7,
          ratio: 23,
          mode: 3,
        ),
        trackMixing: TrackMixingSnapshot(
          enabled: true,
          forwardRatio: 10,
          backwardRatio: 20,
          leftRatio: 30,
          rightRatio: 40,
        ),
        driveMixing: DriveMixingSnapshot(
          enabled: true,
          channel: 6,
          frontRatio: 90,
          rearRatio: 70,
          mode: 2,
        ),
        brakeMixing: BrakeMixingSnapshot(
          enabled: true,
          channel: 8,
          ratio: 66,
          curve: -22,
        ),
      ),
    );

    await notifier.resetDefaultsForScreen(
      Screen.mixing,
      resetAllMixingModes: true,
    );
    final next = container.read(rcAppStateProvider);
    expect(next.protocol.fourWheelSteer.enabled, isFalse);
    expect(next.protocol.fourWheelSteer.channel, 2);
    expect(next.protocol.fourWheelSteer.ratio, 100);
    expect(next.protocol.fourWheelSteer.mode, 0);
    expect(next.protocol.trackMixing.enabled, isFalse);
    expect(next.protocol.trackMixing.forwardRatio, 100);
    expect(next.protocol.trackMixing.backwardRatio, 100);
    expect(next.protocol.trackMixing.leftRatio, 100);
    expect(next.protocol.trackMixing.rightRatio, 100);
    expect(next.protocol.driveMixing.enabled, isFalse);
    expect(next.protocol.driveMixing.channel, 2);
    expect(next.protocol.driveMixing.frontRatio, 100);
    expect(next.protocol.driveMixing.rearRatio, 100);
    expect(next.protocol.driveMixing.mode, 0);
    expect(next.protocol.brakeMixing.enabled, isFalse);
    expect(next.protocol.brakeMixing.channel, 2);
    expect(next.protocol.brakeMixing.ratio, 100);
    expect(next.protocol.brakeMixing.curve, 0);
    expect(next.mixingSettings.activeMode, 'BRAKE');
  });

  test('channel realtime updates do not change track mixing ratios', () {
    final container = _container();
    addTearDown(container.dispose);
    final notifier = container.read(rcAppStateProvider.notifier);
    notifier.state = RcAppState.initial().copyWith(
      protocol: const RcProtocolState(
        rawPayloadByCommand: <int, List<int>>{},
        curveValues: <int>[0, 0, 0],
        trackMixing: TrackMixingSnapshot(
          enabled: true,
          forwardRatio: 11,
          backwardRatio: 22,
          leftRatio: 33,
          rightRatio: 44,
        ),
      ),
    );
    final channels = container.read(rcAppStateProvider).channels;

    notifier.dispatch(
      ChannelUpdatedIntent(id: 'CH1', next: channels[0].copyWith(value: 57)),
    );
    notifier.dispatch(
      ChannelUpdatedIntent(id: 'CH2', next: channels[1].copyWith(value: -32)),
    );

    final track = container.read(rcAppStateProvider).protocol.trackMixing;
    expect(track.forwardRatio, 11);
    expect(track.backwardRatio, 22);
    expect(track.leftRatio, 33);
    expect(track.rightRatio, 44);
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/page/secondary/mixing.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/types.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  testWidgets('track mixing progress uses ch1 and ch2 realtime values', (
    tester,
  ) async {
    await _pumpMixing(tester);

    final control = tester.widget<TankControl>(find.byType(TankControl));
    expect(control.leftTrackValue, 57);
    expect(control.rightTrackValue, -32);

    final tracks = tester
        .widgetList<TankProgressTrack>(find.byType(TankProgressTrack))
        .toList();
    expect(tracks, hasLength(2));
    expect(tracks[0].value, 57);
    expect(tracks[1].value, -32);
    expect(tracks[1].flipX, isTrue);
  });
}

Future<void> _pumpMixing(WidgetTester tester) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Mixing(
          settings: const MixingSettings(
            activeMode: 'TRACK',
            enabled: true,
            ratio: 0,
            curve: 0,
            direction: 'SAME',
            selectedChannel: 'CH3',
          ),
          protocol: const RcProtocolState(
            rawPayloadByCommand: <int, List<int>>{},
            curveValues: <int>[0, 0, 0],
            trackMixing: TrackMixingSnapshot(enabled: true),
          ),
          channels: [_channel('CH1', 57), _channel('CH2', -32)],
          onUpdateSettings: (_) {},
        ),
      ),
    ),
  );
}

ChannelState _channel(String id, int value) {
  return ChannelState(
    id: id,
    name: '',
    value: value,
    lLimit: 0,
    rLimit: 0,
    reverse: false,
    offset: 0,
    dualRate: 0,
    failsafeActive: false,
    failsafeValue: 0,
  );
}

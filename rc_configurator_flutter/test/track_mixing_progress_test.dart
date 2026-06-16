import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/l10n/app_localizations.dart';
import 'package:rc_configurator_flutter/src/page/secondary/mixing.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_models.dart';
import 'package:rc_configurator_flutter/src/types.dart';
import 'package:rc_ui/src/components/progress/rc_progress_track.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  testWidgets('track mixing progress uses ch1 and ch2 realtime values', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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

  testWidgets('track mixing output scale clamps to 100', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpMixing(tester, left: 120, right: -120);

    final control = tester.widget<TankControl>(find.byType(TankControl));
    expect(control.leftTrackValue, 120);
    expect(control.rightTrackValue, -120);

    final tracks = tester
        .widgetList<RcProgressTrack>(find.byType(RcProgressTrack))
        .toList();
    expect(tracks, hasLength(2));
    expect(tracks[0].max, 120);
    expect(tracks[0].controlMax, 120);
    expect(tracks[1].max, 120);
    expect(tracks[1].controlMax, 120);
  });
}

Future<void> _pumpMixing(
  WidgetTester tester, {
  int left = 57,
  int right = -32,
}) {
  return tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(0.8)),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
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
            channels: [_channel('CH1', left), _channel('CH2', right)],
            onUpdateSettings: (_) {},
          ),
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

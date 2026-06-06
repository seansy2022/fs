import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';

import 'package:rc_configurator_flutter/src/page/secondary/channel_travel.dart';
import 'package:rc_configurator_flutter/src/page/secondary/sub_trim.dart';
import 'package:rc_configurator_flutter/src/types.dart';

void main() {
  testWidgets('channel travel step buttons match sub trim size', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_travel()));
    final travelSize = tester.getSize(_progressButtons().first);

    await tester.pumpWidget(_app(_subTrim()));
    final subTrimSize = tester.getSize(_progressButtons().first);

    expect(travelSize.width, closeTo(subTrimSize.width, 0.01));
    expect(travelSize.height, closeTo(subTrimSize.height, 0.01));
  });

  testWidgets('channel travel updates only selected side', (tester) async {
    ChannelState? last;
    await tester.pumpWidget(
      _app(
        ChannelTravel(
          channels: [_channel()],
          onUpdateChannel: (_, next) => last = next,
        ),
      ),
    );

    await tester.tap(_progressButtons().at(1));
    await tester.pump();
    expect(last?.lLimit, 6);
    expect(last?.rLimit, 6);

    last = null;
    await tester.tap(find.text('R:6%'));
    await tester.pump();
    await tester.tap(_progressButtons().at(1));
    await tester.pump();
    expect(last?.lLimit, 5);
    expect(last?.rLimit, 7);
  });
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _travel() {
  return ChannelTravel(channels: [_channel()], onUpdateChannel: (_, __) {});
}

Widget _subTrim() {
  return SubTrim(channels: [_channel()], onUpdateChannel: (_, __) {});
}

Finder _progressButtons() {
  return find.descendant(
    of: find.byType(ControlProgressBar),
    matching: find.byType(RCIconButton),
  );
}

ChannelState _channel() {
  return const ChannelState(
    id: 'CH1',
    name: 'CH1',
    value: 0,
    lLimit: 5,
    rLimit: 6,
    reverse: false,
    offset: 10,
    dualRate: 100,
    failsafeActive: false,
    failsafeValue: 0,
  );
}

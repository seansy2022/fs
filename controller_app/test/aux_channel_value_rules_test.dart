import 'package:controller_app/src/features/settings/models/aux_channel_value_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aux percent is clamped to the extended range', () {
    expect(normalizeAuxChannelPercent(-999), -120);
    expect(normalizeAuxChannelPercent(-100), -100);
    expect(normalizeAuxChannelPercent(0), 0);
    expect(normalizeAuxChannelPercent(120), 120);
    expect(normalizeAuxChannelPercent(999), 120);
  });

  test('multi-state defaults to three configured values', () {
    expect(normalizeAuxMultiStateValues(const <double>[]), const <double>[
      -100,
      0,
      100,
    ]);
  });

  test('multi-state keeps between three and five states', () {
    expect(normalizeAuxMultiStateValues(const <double>[10]), const <double>[
      10,
      0,
      100,
    ]);
    expect(
      normalizeAuxMultiStateValues(const <double>[1, 2, 3, 4, 5, 6]),
      const <double>[1, 2, 3, 4, 5],
    );
  });

  test('multi-state editing applies value and count limits', () {
    expect(
      updateAuxMultiStateValue(const <double>[-100, 0, 100], 1, 130),
      const <double>[-100, 120, 100],
    );
    expect(
      addAuxMultiStateValue(const <double>[-100, 0, 100, 30, 60]),
      const <double>[-100, 0, 100, 30, 60],
    );
    expect(
      removeAuxMultiStateValue(const <double>[-100, 0, 100]),
      const <double>[-100, 0, 100],
    );
  });
}

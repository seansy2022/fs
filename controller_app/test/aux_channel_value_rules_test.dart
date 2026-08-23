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

  test('multi-state labels restore defaults and keep custom names aligned', () {
    expect(
      normalizeAuxMultiStateLabels(const <String>[], stateCount: 5),
      const <String>['状态 1', '状态 2', '状态 3', '自定义名称', '自定义名称'],
    );
    expect(
      normalizeAuxMultiStateLabels(const <String>[
        '低速',
        '',
        '高速',
        '灯光',
      ], stateCount: 4),
      const <String>['低速', '状态 2', '高速', '灯光'],
    );
    expect(
      normalizeAuxMultiStateLabels(const <String>[
        '状态1',
        '状态2',
        '状态3',
      ], stateCount: 3),
      const <String>['状态 1', '状态 2', '状态 3'],
    );
  });

  test('only custom multi-state values can be removed by index', () {
    expect(
      removeAuxMultiStateValueAt(const <double>[-100, 0, 100, 30, 60], 1),
      const <double>[-100, 0, 100, 30, 60],
    );
    expect(
      removeAuxMultiStateValueAt(const <double>[-100, 0, 100, 30, 60], 3),
      const <double>[-100, 0, 100, 60],
    );
  });
}

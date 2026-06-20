import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/provider/control_mapping_labels.dart';

void main() {
  group('ControlMappingLabels', () {
    test('maps popup labels to English display text', () {
      const locale = Locale('en');
      const expected = <String, String>{
        'Click': 'Single press',
        'Double Click': 'Double press',
        'Triple Click': 'Triple press',
        '2-Pos': '2 POS',
        '3-Pos': '3 POS',
        '3-Pos Switch': '3 POS',
        '4WS Mode Switch': '4WS Mixing Mode',
        '4WS Front': '4WS Mixing Front',
        '4WS Rear': '4WS Mixing Rear',
        '4WS F/R Same': '4WS Mixing Same',
        '4WS F/R Reverse': '4WS Mixing Rev.',
        'Drive Mix Toggle': 'Drive Mix Mode',
        'Drive Mix F/R Hybrid': 'Drive Mix F-R Drive',
        'Drive Mix Front': 'Drive Mix F Drive',
        'Drive Mix Rear': 'Drive Mix R Drive',
        'Drive Mix Forward Ratio': 'Drive Mix F Rate',
        'Drive Mix Reverse Ratio': 'Drive Mix R Rate',
        '4WS Mix Ratio': '4WS Mix Rate',
        'Steering Trim': 'Steering Trim',
        'Throttle Trim': 'Throttle Trim',
        'Forward Ratio': 'F Rate',
        'Brake Ratio': 'B Rate',
        'Brake Mix Ratio': 'Brake Mix Rate',
        'Steering Ratio': 'Steering Rate',
      };
      for (final entry in expected.entries) {
        expect(
          ControlMappingLabels.displayLabel(entry.key, locale),
          entry.value,
        );
      }
    });

    test('converts English popup text back to internal ids', () {
      const locale = Locale('en');
      const expected = <String, String>{
        'Single press': 'Click',
        'Double press': 'Double Click',
        'Triple press': 'Triple Click',
        '2 POS': '2-Pos',
        '3 POS': '3-Pos',
        '4WS Mixing Mode': '4WS Mode Switch',
        '4WS Mixing Front': '4WS Front',
        '4WS Mixing Rear': '4WS Rear',
        '4WS Mixing Same': '4WS F/R Same',
        '4WS Mixing Rev.': '4WS F/R Reverse',
        'Drive Mix Mode': 'Drive Mix Toggle',
        'Drive Mix F-R Drive': 'Drive Mix F/R Hybrid',
        'Drive Mix F Drive': 'Drive Mix Front',
        'Drive Mix R Drive': 'Drive Mix Rear',
        'Drive Mix F Rate': 'Drive Mix Forward Ratio',
        'Drive Mix R Rate': 'Drive Mix Reverse Ratio',
        '4WS Mix Rate': '4WS Mix Ratio',
        'Steering Trim': 'Steering Trim',
        'Throttle Trim': 'Throttle Trim',
        'F Rate': 'Forward Ratio',
        'B Rate': 'Brake Ratio',
        'Brake Mix Rate': 'Brake Mix Ratio',
        'Steering Rate': 'Steering Ratio',
      };
      for (final entry in expected.entries) {
        expect(ControlMappingLabels.internalId(entry.key, locale), entry.value);
      }
    });

    test('uses option context for duplicated English labels', () {
      const locale = Locale('en');
      expect(
        ControlMappingLabels.internalIdForOptions(
          '3 POS',
          locale,
          const ['Knob', '3-Pos Switch'],
        ),
        '3-Pos Switch',
      );
      expect(
        ControlMappingLabels.internalIdForOptions(
          '3 POS',
          locale,
          const ['3-Pos'],
        ),
        '3-Pos',
      );
    });

    test('keeps Chinese mappings aligned', () {
      const locale = Locale('zh');
      expect(ControlMappingLabels.displayLabel('Click', locale), '单击');
      expect(ControlMappingLabels.internalId('单击', locale), 'Click');
      expect(ControlMappingLabels.displayLabel('Double Click', locale), '双击');
      expect(ControlMappingLabels.displayLabel('Triple Click', locale), '三击');
      expect(ControlMappingLabels.displayLabel('3-Pos Switch', locale), '三档');
      expect(ControlMappingLabels.internalId('三档', locale), '3-Pos');
    });
  });
}

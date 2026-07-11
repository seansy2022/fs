import 'package:controller_app/src/features/settings/widgets/numeric_input_value_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('display value uses absolute magnitude for fixed negative prefix', () {
    expect(displayNumericInputValue('-80', fixedNegativePrefix: true), '80');
    expect(displayNumericInputValue('0', fixedNegativePrefix: true), '0');
    expect(displayNumericInputValue('50', fixedNegativePrefix: false), '50');
  });

  test('submitted value restores fixed negative prefix', () {
    expect(submitNumericInputValue('80', fixedNegativePrefix: true), '-80');
    expect(submitNumericInputValue('0', fixedNegativePrefix: true), '0');
    expect(submitNumericInputValue('-20', fixedNegativePrefix: false), '-20');
  });

  test('absolute value limit guard rejects values above max', () {
    final formatter = absoluteValueLimitGuard(maxAbsValue: 100);
    const oldValue = TextEditingValue(text: '99');

    expect(
      formatter.formatEditUpdate(oldValue, const TextEditingValue(text: '100')),
      const TextEditingValue(text: '100'),
    );
    expect(
      formatter.formatEditUpdate(
        oldValue,
        const TextEditingValue(text: '9999'),
      ),
      oldValue,
    );
    expect(
      formatter.formatEditUpdate(
        oldValue,
        const TextEditingValue(text: '-101'),
      ),
      oldValue,
    );
  });
}

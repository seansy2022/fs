import 'package:controller_app/src/features/settings/controllers/channel_value_constraints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('low channel percent only allows negative range through zero', () {
    final constraint = channelPercentConstraintFor(ChannelValueField.low);

    expect(constraint.min, -100);
    expect(constraint.max, 0);
    expect(constraint.allowNegativeInput, isTrue);
    expect(constraint.allowPositiveInput, isFalse);
    expect(constraint.fixedNegativePrefix, isTrue);
    expect(constraint.normalize(-120), -100);
    expect(constraint.normalize(-80), -80);
    expect(constraint.normalize(0), 0);
    expect(constraint.normalize(60), 0);
  });

  test('high channel percent only allows positive range from zero', () {
    final high = channelPercentConstraintFor(ChannelValueField.high);

    expect(high.min, 0);
    expect(high.max, 100);
    expect(high.allowNegativeInput, isFalse);
    expect(high.allowPositiveInput, isTrue);
    expect(high.fixedNegativePrefix, isFalse);
    expect(high.normalize(-60), 0);
    expect(high.normalize(0), 0);
    expect(high.normalize(60), 60);
    expect(high.normalize(120), 100);
  });

  test('trim channel percent keeps signed full range', () {
    final trim = channelPercentConstraintFor(ChannelValueField.trim);

    expect(trim.min, -100);
    expect(trim.max, 100);
    expect(trim.allowNegativeInput, isTrue);
    expect(trim.allowPositiveInput, isTrue);
    expect(trim.fixedNegativePrefix, isFalse);
    expect(trim.normalize(-120), -100);
    expect(trim.normalize(60), 60);
    expect(trim.normalize(120), 100);
  });
}

enum ChannelValueField { low, high, trim }

class ChannelPercentConstraint {
  const ChannelPercentConstraint({
    required this.min,
    required this.max,
    required this.allowNegativeInput,
    required this.allowPositiveInput,
    required this.fixedNegativePrefix,
  });

  final int min;
  final int max;
  final bool allowNegativeInput;
  final bool allowPositiveInput;
  final bool fixedNegativePrefix;

  int get maxAbsValue => min.abs() > max.abs() ? min.abs() : max.abs();

  int normalize(int value) => value.clamp(min, max).toInt();
}

ChannelPercentConstraint channelPercentConstraintFor(ChannelValueField field) {
  switch (field) {
    case ChannelValueField.low:
      return const ChannelPercentConstraint(
        min: -100,
        max: 0,
        allowNegativeInput: true,
        allowPositiveInput: false,
        fixedNegativePrefix: true,
      );
    case ChannelValueField.high:
      return const ChannelPercentConstraint(
        min: 0,
        max: 100,
        allowNegativeInput: false,
        allowPositiveInput: true,
        fixedNegativePrefix: false,
      );
    case ChannelValueField.trim:
      return const ChannelPercentConstraint(
        min: -100,
        max: 100,
        allowNegativeInput: true,
        allowPositiveInput: true,
        fixedNegativePrefix: false,
      );
  }
}

import 'package:controller_app/src/core/receiver_battery_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('raw receiver percent maps to the fixed 3.5V to 8.5V range', () {
    final empty = ReceiverBatteryStatus.fromRawBatteryLevel(
      rawBatteryLevel: 0,
      minimumVoltage: 3.5,
      fullVoltage: 8.5,
    );
    final full = ReceiverBatteryStatus.fromRawBatteryLevel(
      rawBatteryLevel: 100,
      minimumVoltage: 3.5,
      fullVoltage: 8.5,
    );

    expect(empty.voltage, 3.5);
    expect(empty.displayPercent, 0);
    expect(full.voltage, 8.5);
    expect(full.displayPercent, 100);
  });

  test(
    'configured voltage range controls display percent and five icon levels',
    () {
      final empty = ReceiverBatteryStatus.fromRawBatteryLevel(
        rawBatteryLevel: 50,
        minimumVoltage: 6.0,
        fullVoltage: 8.5,
      );
      final firstLevel = ReceiverBatteryStatus.fromRawBatteryLevel(
        rawBatteryLevel: 60,
        minimumVoltage: 6.0,
        fullVoltage: 8.5,
      );
      final full = ReceiverBatteryStatus.fromRawBatteryLevel(
        rawBatteryLevel: 100,
        minimumVoltage: 6.0,
        fullVoltage: 8.5,
      );

      expect(empty.voltage, 6.0);
      expect(empty.displayPercent, 0);
      expect(empty.iconPercent, 0);
      expect(firstLevel.displayPercent, 20);
      expect(firstLevel.iconPercent, 20);
      expect(full.iconPercent, 100);
    },
  );

  test('icon level rounds up within each of the five voltage segments', () {
    final status = ReceiverBatteryStatus.fromRawBatteryLevel(
      rawBatteryLevel: 61,
      minimumVoltage: 6.0,
      fullVoltage: 8.5,
    );

    expect(status.displayPercent, 22);
    expect(status.iconPercent, 40);
  });

  test('alert threshold includes the exact configured battery percent', () {
    final status = ReceiverBatteryStatus.fromRawBatteryLevel(
      rawBatteryLevel: 15,
      minimumVoltage: 3.5,
      fullVoltage: 8.5,
    );

    expect(status.isAtOrBelow(15), isTrue);
    expect(status.isAtOrBelow(14), isFalse);
  });

  test('invalid configured range safely reports an empty battery', () {
    final status = ReceiverBatteryStatus.fromRawBatteryLevel(
      rawBatteryLevel: 100,
      minimumVoltage: 8.5,
      fullVoltage: 8.5,
    );

    expect(status.displayPercent, 0);
    expect(status.iconPercent, 0);
  });
}

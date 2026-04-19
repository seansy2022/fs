import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  test('crc8 follows protocol polynomial with init 0xFF', () {
    expect(calculateBluetoothCrc8(const []), 0xFF);
    expect(calculateBluetoothCrc8(const [0x00]), 0x60);
    expect(calculateBluetoothCrc8(const [0x01]), 0x45);
  });

  test('frame encode and parse round-trip', () {
    final frame = BluetoothFrame(
      seq: 2,
      command: 0x15,
      length: 2,
      data: [0xF1, 0x24],
    );
    final encoded = frame.toBytes();
    final parsed = BluetoothFrame.tryParse(encoded);
    expect(parsed, isNotNull);
    expect(parsed!.seq, 2);
    expect(parsed.command, 0x15);
    expect(parsed.length, 2);
    expect(parsed.data[0], 0xF1);
    expect(parsed.data[1], 0x24);
  });

  test('parser handles split chunks and invalid prefix bytes', () {
    final frame = BluetoothFrame(
      seq: 1,
      command: 0x11,
      length: 1,
      data: [1],
    ).toBytes();
    final parser = BluetoothFrameParser();
    expect(parser.append(const [0x00, 0x01]).length, 0);
    expect(parser.append(frame.sublist(0, 10)).length, 0);
    final out = parser.append(frame.sublist(10));
    expect(out.length, 1);
    expect(out.first.command, 0x11);
  });

  test('codec parses channel display and telemetry packets', () {
    final chData = List<int>.filled(24, 0);
    chData[0] = 0x03;
    chData[1] = 0xE8;
    chData[2] = 0x07;
    chData[3] = 0xD0;
    final chFrame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.channelDisplay.id,
      length: 22,
      data: chData,
    );
    final channels = parseChannelDisplay(chFrame);
    expect(channels, isNotNull);
    expect(channels!.values[0], 1000);
    expect(channels.values[1], 2000);

    final tmData = List<int>.filled(24, 0);
    tmData[0] = 0x7F;
    tmData[1] = 0x01;
    tmData[2] = 0x32;
    tmData[3] = 0x00;
    final tmFrame = BluetoothFrame(
      seq: 1,
      command: BluetoothCommand.telemetryDisplay.id,
      length: 4,
      data: tmData,
    );
    final telemetry = parseTelemetryDisplay(tmFrame);
    expect(telemetry, isNotNull);
    expect(telemetry!.values.first.sensorType, 0x7F);
    expect(telemetry.values.first.rawValue, 50);
  });

  test('codec parses telemetry fixed layout fallback', () {
    final tmData = List<int>.filled(24, 0);
    tmData[0] = 0x00;
    tmData[1] = 0x34;
    tmData[2] = 0x00;
    tmData[3] = 0x2F;
    tmData[4] = 0x3E;
    final tmFrame = BluetoothFrame(
      seq: 0xD3,
      command: BluetoothCommand.telemetryDisplay.id,
      length: 24,
      data: tmData,
    );
    final telemetry = parseTelemetryDisplay(tmFrame);
    expect(telemetry, isNotNull);
    expect(telemetry!.values[0].rawValue, 0x0034);
    expect(telemetry.values[1].rawValue, 0x002F);
    expect(telemetry.values[2].rawValue, 0x3E);
  });
}

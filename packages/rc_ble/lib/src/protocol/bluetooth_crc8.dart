int calculateBluetoothCrc8(List<int> bytes, {int initial = 0xFF}) {
  var crc = initial & 0xFF;
  for (final value in bytes) {
    crc ^= value & 0xFF;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x80) != 0 ? ((crc << 1) ^ 0x25) & 0xFF : (crc << 1) & 0xFF;
    }
  }
  return crc & 0xFF;
}

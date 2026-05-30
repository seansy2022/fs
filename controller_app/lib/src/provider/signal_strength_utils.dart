int rssiToPercent(int? rssi) {
  if (rssi == null) {
    return 0;
  }
  if (rssi >= -50) {
    return 100;
  }
  if (rssi >= -65) {
    return 75;
  }
  if (rssi >= -80) {
    return 50;
  }
  if (rssi >= -95) {
    return 25;
  }
  return 0;
}

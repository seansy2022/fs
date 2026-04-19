int calculateReceiverChecksum16(List<int> bytes) {
  var sum = 0;
  for (final value in bytes) {
    sum = (sum + (value & 0xFF)) & 0xFFFF;
  }
  return sum;
}

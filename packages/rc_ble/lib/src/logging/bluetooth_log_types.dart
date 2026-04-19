class BluetoothLogEntry {
  const BluetoothLogEntry({
    required this.id,
    required this.timestampMs,
    required this.direction,
    required this.command,
    required this.dataText,
  });

  final int id;
  final int timestampMs;
  final String direction;
  final String command;
  final String dataText;
}

abstract class BluetoothLogStore {
  Future<void> init();
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
  Future<void> append({
    required String direction,
    required String command,
    required String dataText,
  });
  Future<List<BluetoothLogEntry>> listAllAsc();
}

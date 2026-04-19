/// rc_ble — BLE transport, protocol frame layer, and logging.
///
/// Provides:
///   - [LinkTransport] abstraction and BLE/mock implementations
///   - [BluetoothProtocolClient] for frame-level communication
///   - Logging utilities
library rc_ble;

// Link / Transport
export 'src/link/link_transport.dart';
export 'src/link/ble_transport_flutter_blue.dart';
export 'src/link/memory_link_transport.dart';
export 'src/link/mock_protocol_link_transport.dart';

// Protocol (frame layer)
export 'src/protocol/bluetooth_crc8.dart';
export 'src/protocol/bluetooth_frame.dart';
export 'src/protocol/bluetooth_frame_parser.dart';
export 'src/protocol/bluetooth_protocol_client.dart';
export 'src/protocol/bluetooth_protocol_codec.dart';
export 'src/protocol/bluetooth_protocol_types.dart';

// Logging
export 'src/logging/bluetooth_log_store.dart';
export 'src/logging/bluetooth_log_types.dart';
export 'src/logging/rc_logging.dart';

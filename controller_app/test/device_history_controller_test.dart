import 'package:controller_app/src/features/bluetooth/controllers/device_history_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('device history keeps most recent 10 devices', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = DeviceHistoryController();

    await Future<void>.delayed(Duration.zero);
    for (var index = 0; index < 12; index++) {
      await controller.rememberDevice(
        ReceiverScanDevice(
          remoteId: 'dev-$index',
          name: 'Receiver $index',
          rssi: -40,
        ),
      );
    }

    expect(controller.state, hasLength(10));
    expect(controller.state.first.remoteId, 'dev-11');
    expect(controller.state.last.remoteId, 'dev-2');
  });
}

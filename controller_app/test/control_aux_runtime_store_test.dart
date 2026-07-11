import 'package:controller_app/src/features/control/controllers/control_aux_runtime_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('saveChannel keeps CH3 and CH4 runtime records', () async {
    final store = ControlAuxRuntimeStore();

    await store.saveChannel(
      2,
      const StoredAuxChannelRuntime(selectedIndex: 2, switchOn: false),
    );
    await store.saveChannel(
      3,
      const StoredAuxChannelRuntime(selectedIndex: 0, switchOn: true),
    );

    final saved = await store.load();

    expect(saved[2]?.selectedIndex, 2);
    expect(saved[2]?.switchOn, isFalse);
    expect(saved[3]?.selectedIndex, 0);
    expect(saved[3]?.switchOn, isTrue);
  });

  test('load ignores invalid stored json', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'controller_app.control_aux_runtime.v1': '{bad json',
    });

    final saved = await ControlAuxRuntimeStore().load();

    expect(saved, isEmpty);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/provider/control_mapping_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rc_ble/rc_ble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('selectChannel applies channel-specific type options', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(controlMappingProvider.notifier);

    notifier.selectChannel('CH3');
    var state = container.read(controlMappingProvider);
    expect(state.type, '单击');
    expect(state.mode, '翻转');
    expect(state.availableStates, ['单击', '双击', '三击', '长按']);

    notifier.selectChannel('CH5');
    state = container.read(controlMappingProvider);
    expect(state.type, '旋钮');
    expect(state.availableStates, ['旋钮', '三档开关']);
  });

  test('CH5 three-way switch initializes and updates mode options', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(controlMappingProvider.notifier);

    notifier.selectChannel('CH5');
    notifier.updateType('三档开关');
    var state = container.read(controlMappingProvider);
    expect(state.action, '四轮混控');
    expect(state.mixingFunction, '四轮');
    expect(state.mixingMode1, '四轮转向前面');
    expect(state.mixingMode2, '四轮转向后面');
    expect(state.mixingMode3, '四轮转向前后同向');

    notifier.updateMixingMode(1, '四轮转向后面');
    state = container.read(controlMappingProvider);
    expect(state.mixingMode1, '四轮转向后面');
    expect(state.mixingMode2, '四轮转向前面');
    expect(state.mixingMode3, '四轮转向前后同向');

    notifier.updateAction('驱动混控');
    state = container.read(controlMappingProvider);
    expect(state.action, '驱动混控');
    expect(state.mixingFunction, '混动');
    expect(state.mixingMode1, '驱动混控前面');
    expect(state.mixingMode2, '驱动混控后面');
    expect(state.mixingMode3, '驱动混控前后混控');
    final unique = {state.mixingMode1, state.mixingMode2, state.mixingMode3};
    expect(unique.length, 3);
  });

  test('channel action writes targetChannel and non-channel clears it', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(controlMappingProvider.notifier);

    notifier.selectChannel('CH3');
    notifier.updateAction('CH8');
    var state = container.read(controlMappingProvider);
    expect(state.targetChannel, 'CH8');

    notifier.updateAction('四轮转向开关');
    state = container.read(controlMappingProvider);
    expect(state.targetChannel, isNull);
  });

  test('CH5 knob uses CH9 function mode options', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(controlMappingProvider.notifier);

    notifier.selectChannel('CH5');
    notifier.updateType('旋钮');
    notifier.updateAction('方向微调');
    var state = container.read(controlMappingProvider);
    expect(state.action, '方向微调');
    expect(state.targetChannel, isNull);

    notifier.updateAction('CH8');
    state = container.read(controlMappingProvider);
    expect(state.action, 'CH8');
    expect(state.targetChannel, 'CH8');
  });

  test('switching channels restores saved mapping state', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(controlMappingProvider.notifier);

    notifier.selectChannel('CH3');
    notifier.updateAction('CH8');
    notifier.updateMode('触发');

    notifier.selectChannel('CH5');
    notifier.updateType('三档开关');
    notifier.updateAction('驱动混控');

    notifier.selectChannel('CH3');
    final restoredCh3 = container.read(controlMappingProvider);
    expect(restoredCh3.channel, 'CH3');
    expect(restoredCh3.action, 'CH8');
    expect(restoredCh3.mode, '触发');

    notifier.selectChannel('CH5');
    final restoredCh5 = container.read(controlMappingProvider);
    expect(restoredCh5.channel, 'CH5');
    expect(restoredCh5.type, '三档开关');
    expect(restoredCh5.action, '驱动混控');
  });
}

ProviderContainer _createContainer() {
  return ProviderContainer(
    overrides: [
      linkTransportProvider.overrideWithValue(
        MemoryLinkTransport(linkType: LinkType.usb),
      ),
    ],
  );
}

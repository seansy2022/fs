import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/provider/app_state_provider.dart';
import 'package:rc_configurator_flutter/src/provider/control_mapping_options.dart';
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
    expect(state.type, 'Click');
    expect(state.mode, 'Flip');
    expect(state.availableStates, ['Click', 'Double Click', 'Triple Click', 'Long Press']);

    notifier.selectChannel('CH5');
    state = container.read(controlMappingProvider);
    expect(state.type, 'Knob');
    expect(state.availableStates, ['Knob', '3-Pos Switch']);
  });

  test('CH5 three-way switch initializes and updates mode options', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(controlMappingProvider.notifier);

    notifier.selectChannel('CH5');
    notifier.updateType('3-Pos Switch');
    var state = container.read(controlMappingProvider);
    expect(functionModeOptionsForChannel('CH5', type: '3-Pos Switch'), [
      ...controlMappingChannels,
      '4W Mix',
      'Drive Mix',
      controlMappingNoAction,
    ]);
    expect(state.action, 'CH5');
    expect(state.targetChannel, 'CH5');
    expect(state.mixingFunction, isNull);
    expect(state.mixingMode1, isNull);
    notifier.updateAction('4W Mix');
    state = container.read(controlMappingProvider);
    expect(state.action, '4W Mix');
    expect(state.mixingFunction, '4W');
    expect(state.mixingMode1, '4WS Front');
    expect(state.mixingMode2, '4WS Rear');
    expect(state.mixingMode3, '4WS F/R Same');

    notifier.updateMixingMode(1, '4WS Rear');
    state = container.read(controlMappingProvider);
    expect(state.mixingMode1, '4WS Rear');
    expect(state.mixingMode2, '4WS Front');
    expect(state.mixingMode3, '4WS F/R Same');

    notifier.updateAction('Drive Mix');
    state = container.read(controlMappingProvider);
    expect(state.action, 'Drive Mix');
    expect(state.mixingFunction, 'Hybrid');
    expect(state.mixingMode1, 'Drive Mix Rear');
    expect(state.mixingMode2, 'Drive Mix F/R Hybrid');
    expect(state.mixingMode3, 'Drive Mix Front');
    final unique = {state.mixingMode1, state.mixingMode2, state.mixingMode3};
    expect(unique.length, 3);

    notifier.updateAction('CH8');
    state = container.read(controlMappingProvider);
    expect(state.action, 'CH8');
    expect(state.targetChannel, 'CH8');
    expect(state.mixingFunction, isNull);
    expect(state.mixingMode1, isNull);
    expect(state.mixingMode2, isNull);
    expect(state.mixingMode3, isNull);

    notifier.updateAction(controlMappingNoAction);
    state = container.read(controlMappingProvider);
    expect(state.action, controlMappingNoAction);
    expect(state.targetChannel, isNull);
    expect(state.mixingFunction, isNull);
  });

  test('channel action writes targetChannel and non-channel clears it', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(controlMappingProvider.notifier);

    notifier.selectChannel('CH3');
    notifier.updateAction('CH8');
    var state = container.read(controlMappingProvider);
    expect(state.targetChannel, 'CH8');

    notifier.updateAction('4WS Switch');
    state = container.read(controlMappingProvider);
    expect(state.targetChannel, isNull);
  });

  test('CH5 knob only uses channel function modes and defaults to CH5', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(controlMappingProvider.notifier);

    notifier.selectChannel('CH5');
    notifier.updateType('Knob');
    var state = container.read(controlMappingProvider);
    expect(state.action, 'CH5');
    expect(state.targetChannel, 'CH5');
    final options = functionModeOptionsForChannel('CH5', type: 'Knob');
    expect(options, [...controlMappingChannels, controlMappingNoAction]);

    notifier.updateAction('CH8');
    state = container.read(controlMappingProvider);
    expect(state.action, 'CH8');
    expect(state.targetChannel, 'CH8');

    notifier.updateAction(controlMappingNoAction);
    state = container.read(controlMappingProvider);
    expect(state.action, controlMappingNoAction);
    expect(state.targetChannel, isNull);
  });

  test('CH6 uses only three-way type and mirrors CH5 three-way actions', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(controlMappingProvider.notifier);
    notifier.selectChannel('CH6');
    var state = container.read(controlMappingProvider);
    final ch6Types = controlTypeOptionsForChannel('CH6');
    final ch5ThreeWayType = controlTypeOptionsForChannel('CH5').last;
    expect(ch6Types, hasLength(1));
    expect(state.type, ch6Types.first);
    expect(state.availableStates, ch6Types);
    expect(state.action, 'CH6');
    expect(state.targetChannel, 'CH6');
    expect(
      functionModeOptionsForChannel('CH6', type: ch6Types.first),
      functionModeOptionsForChannel('CH5', type: ch5ThreeWayType),
    );
    notifier.updateAction('CH8');
    state = container.read(controlMappingProvider);
    expect(state.action, 'CH8');
    expect(state.targetChannel, 'CH8');
  });

  test('CH10 uses only two-way type and defaults function mode to CH10', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(controlMappingProvider.notifier);
    notifier.selectChannel('CH10');
    final state = container.read(controlMappingProvider);
    final ch10Types = controlTypeOptionsForChannel('CH10');
    expect(ch10Types, hasLength(1));
    expect(state.type, ch10Types.first);
    expect(state.availableStates, ch10Types);
    expect(functionModeOptionsForChannel('CH10', type: state.type), [
      ...controlMappingChannels,
      controlMappingNoAction,
    ]);
    expect(state.action, 'CH10');
    expect(state.targetChannel, 'CH10');
    expect(state.mode, isEmpty);
  });

  test('CH9 function mode options include trim and ratio actions', () {
    final options = functionModeOptionsForChannel('CH9', type: 'Knob');
    expect(options, [
      ...controlMappingChannels,
      'Throttle Trim',
      'Steering Trim',
      '4WS Mix Ratio',
      'Drive Mix Forward Ratio',
      'Drive Mix Reverse Ratio',
      'Brake Mix Ratio',
      'Steering Ratio',
      'Forward Ratio',
      'Brake Ratio',
      controlMappingNoAction,
    ]);
  });

  test('duplicate function confirm clears previous mapping', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(controlMappingProvider.notifier);

    notifier.selectChannel('CH3');
    notifier.updateAction('CH3');
    notifier.selectChannel('CH4');

    expect(notifier.duplicateActionOwner('CH3'), 'CH3');
    notifier.updateActionResolvingDuplicate('CH3', 'CH3');

    final app = container.read(rcAppStateProvider);
    expect(app.controlMappings['CH3']?.action, controlMappingNoAction);
    expect(app.controlMappings['CH3']?.targetChannel, isNull);
    expect(app.controlMappings['CH4']?.action, 'CH3');
    expect(app.controlMappings['CH4']?.targetChannel, 'CH3');
    expect(container.read(controlMappingProvider).channel, 'CH4');
  });

  test('switching channels restores saved mapping state', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(controlMappingProvider.notifier);

    notifier.selectChannel('CH3');
    notifier.updateAction('CH8');
    notifier.updateMode('Trigger');

    notifier.selectChannel('CH5');
    notifier.updateType('3-Pos Switch');
    notifier.updateAction('Drive Mix');

    notifier.selectChannel('CH3');
    final restoredCh3 = container.read(controlMappingProvider);
    expect(restoredCh3.channel, 'CH3');
    expect(restoredCh3.action, 'CH8');
    expect(restoredCh3.mode, 'Trigger');

    notifier.selectChannel('CH5');
    final restoredCh5 = container.read(controlMappingProvider);
    expect(restoredCh5.channel, 'CH5');
    expect(restoredCh5.type, '3-Pos Switch');
    expect(restoredCh5.action, 'Drive Mix');
  });

  test('CH5 legacy "None" type is normalized to knob on selection', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final app = container.read(rcAppStateProvider);
    final notifier = container.read(controlMappingProvider.notifier);
    final appNotifier = container.read(rcAppStateProvider.notifier);
    final legacyCh5 = app.controlMapping.copyWith(
      channel: 'CH5',
      type: 'None',
      selectedState: 'None',
      availableStates: <String>['None', 'Knob', '3-Pos Switch'],
    );
    appNotifier.state = app.copyWith(
      controlMappings: <String, ControlMappingState>{
        ...app.controlMappings,
        'CH5': legacyCh5,
      },
    );
    notifier.selectChannel('CH5');
    final state = container.read(controlMappingProvider);
    expect(state.type, 'Knob');
    expect(state.selectedState, 'Knob');
    expect(state.availableStates, ['Knob', '3-Pos Switch']);
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

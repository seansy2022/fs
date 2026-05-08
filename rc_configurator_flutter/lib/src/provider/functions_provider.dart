import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../types.dart';

class FunctionsController extends Notifier<Screen> {
  @override
  Screen build() => Screen.dashboard;

  void navigate(Screen screen) {
    state = screen;
  }

  void goBack() {
    if ({
      Screen.channels,
      Screen.reverse,
      Screen.subTrim,
      Screen.dualRate,
      Screen.curve,
      Screen.controlMapping,
      Screen.modelSelection,
      Screen.failsafe,
      Screen.radioSettings,
      Screen.mixing,
    }.contains(state)) {
      state = Screen.functions;
      return;
    }
    state = Screen.dashboard;
  }
}

final functionsProvider = NotifierProvider<FunctionsController, Screen>(
  FunctionsController.new,
);

final isSubScreenProvider = Provider<bool>((ref) {
  final screen = ref.watch(functionsProvider);
  return !{
    Screen.dashboard,
    Screen.functions,
    Screen.bluetooth,
  }.contains(screen);
});

final screenTitleProvider = Provider<String>((ref) {
  switch (ref.watch(functionsProvider)) {
    case Screen.dashboard:
      return '';
    case Screen.functions:
      return 'Menu';
    case Screen.channels:
      return 'EPA';
    case Screen.reverse:
      return 'Reverse';
    case Screen.subTrim:
      return 'SUBTRIM';
    case Screen.dualRate:
      return 'D/R';
    case Screen.curve:
      return 'CURVE';
    case Screen.controlMapping:
      return 'ASSIGN';
    case Screen.modelSelection:
      return 'MODEL';
    case Screen.failsafe:
      return 'Failsafe';
    case Screen.radioSettings:
      return 'SYSTEM';
    case Screen.mixing:
      return 'MIXES';
    case Screen.bluetooth:
      return 'BT Connect';
  }
});

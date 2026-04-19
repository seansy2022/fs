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
      return '菜单';
    case Screen.channels:
      return '通道行程';
    case Screen.reverse:
      return '通道反向';
    case Screen.subTrim:
      return '中立微调';
    case Screen.dualRate:
      return '双比率';
    case Screen.curve:
      return '曲线设置';
    case Screen.controlMapping:
      return '控件分配';
    case Screen.modelSelection:
      return '模型选择';
    case Screen.failsafe:
      return '失控保护';
    case Screen.radioSettings:
      return '遥控器设置';
    case Screen.mixing:
      return '混控';
    case Screen.bluetooth:
      return '蓝牙连接';
  }
});

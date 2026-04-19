import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state_provider.dart';
import 'app_state_models.dart';

export 'app_state_models.dart' show CurveState;

class CurveController extends Notifier<CurveState> {
  @override
  CurveState build() {
    return ref.watch(rcAppStateProvider.select((state) => state.curve));
  }

  void selectCurve(String curve) {
    ref.read(rcAppStateProvider.notifier).dispatch(CurveSelectedIntent(curve));
  }

  void updateCurveValue(int value) {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(CurveValueUpdatedIntent(value));
  }

  void reset() {
    ref
        .read(rcAppStateProvider.notifier)
        .dispatch(const CurveValueUpdatedIntent(0));
  }
}

final curveProvider = NotifierProvider<CurveController, CurveState>(
  CurveController.new,
);

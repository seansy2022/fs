import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/control/controllers/control_controller.dart';
import 'gyro_prompt_provider.dart';

final controlControllerProvider =
    StateNotifierProvider.autoDispose<ControlController, ControlScreenState>((
      ref,
    ) {
      final controller = ControlController(
        ref,
        ref.watch(receiverRepositoryProvider),
      );
      ref.listen<AsyncValue<GyroPrompt>>(gyroPromptProvider, (_, next) {
        next.whenData((value) {
          if (!controller.gyroEnabled) {
            return;
          }
          unawaited(
            controller.setGyroPrompt(
              steering: value.steering,
              throttle: value.throttle,
            ),
          );
        });
      });
      return controller;
    });

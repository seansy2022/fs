import 'package:flutter_riverpod/flutter_riverpod.dart';

class StartupState {
  const StartupState({
    required this.isBooting,
    required this.isReady,
    required this.permissionsHandled,
  });

  final bool isBooting;
  final bool isReady;
  final bool permissionsHandled;

  StartupState copyWith({
    bool? isBooting,
    bool? isReady,
    bool? permissionsHandled,
  }) {
    return StartupState(
      isBooting: isBooting ?? this.isBooting,
      isReady: isReady ?? this.isReady,
      permissionsHandled: permissionsHandled ?? this.permissionsHandled,
    );
  }
}

class StartupController extends Notifier<StartupState> {
  @override
  StartupState build() {
    return const StartupState(
      isBooting: true,
      isReady: false,
      permissionsHandled: false,
    );
  }

  Future<void> initialize() async {
    if (state.isReady || !state.isBooting) return;
    await Future<void>.delayed(const Duration(seconds: 2));
    state = state.copyWith(isBooting: false, isReady: true);
  }

  void markPermissionsHandled() {
    if (state.permissionsHandled) return;
    state = state.copyWith(permissionsHandled: true);
  }
}

final startupProvider = NotifierProvider<StartupController, StartupState>(
  StartupController.new,
);

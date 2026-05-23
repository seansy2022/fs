import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/permissions.dart';

enum AppBootstrapStatus { idle, loading, ready, permissionRequired }

class AppBootstrapState {
  const AppBootstrapState({
    required this.status,
    required this.hasBluetoothPermission,
  });

  const AppBootstrapState.initial()
    : status = AppBootstrapStatus.idle,
      hasBluetoothPermission = false;

  final AppBootstrapStatus status;
  final bool hasBluetoothPermission;

  AppBootstrapState copyWith({
    AppBootstrapStatus? status,
    bool? hasBluetoothPermission,
  }) {
    return AppBootstrapState(
      status: status ?? this.status,
      hasBluetoothPermission:
          hasBluetoothPermission ?? this.hasBluetoothPermission,
    );
  }
}

class AppBootstrapController extends StateNotifier<AppBootstrapState> {
  AppBootstrapController() : super(const AppBootstrapState.initial());

  Future<void> bootstrap() async {
    state = state.copyWith(status: AppBootstrapStatus.loading);
    final granted = await hasBluetoothPermissions();
    state = state.copyWith(
      hasBluetoothPermission: granted,
      status: granted
          ? AppBootstrapStatus.ready
          : AppBootstrapStatus.permissionRequired,
    );
  }
}

final appBootstrapProvider =
    StateNotifierProvider<AppBootstrapController, AppBootstrapState>((ref) {
      return AppBootstrapController();
    });

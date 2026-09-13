import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/permissions.dart';

/// 应用级功能开关，集中控制暂时下线但需要保留代码的能力。
class AppFeatureFlags {
  const AppFeatureFlags({this.receiverBatteryEnabled = false});

  /// 接收机电量功能默认关闭，后续恢复时只需修改默认值。
  final bool receiverBatteryEnabled;
}

final appFeatureFlagsProvider = Provider<AppFeatureFlags>((ref) {
  return const AppFeatureFlags();
});

/// App 仅在前台可见时允许播放声音；息屏和后台状态统一设为 false。
final appForegroundProvider = StateProvider<bool>((ref) => true);

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

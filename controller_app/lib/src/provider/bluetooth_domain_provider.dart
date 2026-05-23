import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rc_c_ble/rc_c_ble.dart';

import '../core/providers.dart';
import '../features/bluetooth/controllers/device_history_controller.dart';

enum BluetoothPermissionState {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  unsupported,
}

enum BluetoothAvailability {
  unknown,
  ready,
  bluetoothOff,
  permissionRequired,
  unsupported,
}

enum BluetoothScanPhase { idle, stopping, cooling, starting, scanning, error }

enum BluetoothScanOwner { none, home, listPage }

enum BluetoothBootstrapPrompt { none, permissionRequired, bluetoothOff }

class BluetoothDomainState {
  const BluetoothDomainState({
    required this.adapterState,
    required this.permissionState,
    required this.availability,
    required this.scanPhase,
    required this.scanOwner,
    required this.isScanning,
    required this.isWorking,
    required this.hasBootstrappedHome,
    required this.homeScanEndsAt,
    required this.pendingBootstrapPrompt,
    required this.lastBootstrapPromptAt,
    required this.connectedDevice,
    required this.pairedDevices,
    required this.discoveredDevices,
    this.errorMessage,
  });

  const BluetoothDomainState.initial()
    : adapterState = AdapterState.unknown,
      permissionState = BluetoothPermissionState.unknown,
      availability = BluetoothAvailability.unknown,
      scanPhase = BluetoothScanPhase.idle,
      scanOwner = BluetoothScanOwner.none,
      isScanning = false,
      isWorking = false,
      hasBootstrappedHome = false,
      homeScanEndsAt = null,
      pendingBootstrapPrompt = BluetoothBootstrapPrompt.none,
      lastBootstrapPromptAt = null,
      connectedDevice = null,
      pairedDevices = const <ReceiverDeviceView>[],
      discoveredDevices = const <ReceiverDeviceView>[],
      errorMessage = null;

  final AdapterState adapterState;
  final BluetoothPermissionState permissionState;
  final BluetoothAvailability availability;
  final BluetoothScanPhase scanPhase;
  final BluetoothScanOwner scanOwner;
  final bool isScanning;
  final bool isWorking;
  final bool hasBootstrappedHome;
  final DateTime? homeScanEndsAt;
  final BluetoothBootstrapPrompt pendingBootstrapPrompt;
  final DateTime? lastBootstrapPromptAt;
  final ReceiverDeviceView? connectedDevice;
  final List<ReceiverDeviceView> pairedDevices;
  final List<ReceiverDeviceView> discoveredDevices;
  final String? errorMessage;

  BluetoothDomainState copyWith({
    AdapterState? adapterState,
    BluetoothPermissionState? permissionState,
    BluetoothAvailability? availability,
    BluetoothScanPhase? scanPhase,
    BluetoothScanOwner? scanOwner,
    bool? isScanning,
    bool? isWorking,
    bool? hasBootstrappedHome,
    DateTime? homeScanEndsAt,
    bool clearHomeScanEndsAt = false,
    BluetoothBootstrapPrompt? pendingBootstrapPrompt,
    DateTime? lastBootstrapPromptAt,
    ReceiverDeviceView? connectedDevice,
    bool clearConnectedDevice = false,
    List<ReceiverDeviceView>? pairedDevices,
    List<ReceiverDeviceView>? discoveredDevices,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BluetoothDomainState(
      adapterState: adapterState ?? this.adapterState,
      permissionState: permissionState ?? this.permissionState,
      availability: availability ?? this.availability,
      scanPhase: scanPhase ?? this.scanPhase,
      scanOwner: scanOwner ?? this.scanOwner,
      isScanning: isScanning ?? this.isScanning,
      isWorking: isWorking ?? this.isWorking,
      hasBootstrappedHome: hasBootstrappedHome ?? this.hasBootstrappedHome,
      homeScanEndsAt: clearHomeScanEndsAt
          ? null
          : (homeScanEndsAt ?? this.homeScanEndsAt),
      pendingBootstrapPrompt:
          pendingBootstrapPrompt ?? this.pendingBootstrapPrompt,
      lastBootstrapPromptAt:
          lastBootstrapPromptAt ?? this.lastBootstrapPromptAt,
      connectedDevice: clearConnectedDevice
          ? null
          : (connectedDevice ?? this.connectedDevice),
      pairedDevices: pairedDevices ?? this.pairedDevices,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BluetoothDomainState &&
        other.adapterState == adapterState &&
        other.permissionState == permissionState &&
        other.availability == availability &&
        other.scanPhase == scanPhase &&
        other.scanOwner == scanOwner &&
        other.isScanning == isScanning &&
        other.isWorking == isWorking &&
        other.hasBootstrappedHome == hasBootstrappedHome &&
        other.homeScanEndsAt == homeScanEndsAt &&
        other.pendingBootstrapPrompt == pendingBootstrapPrompt &&
        other.lastBootstrapPromptAt == lastBootstrapPromptAt &&
        other.connectedDevice == connectedDevice &&
        listEquals(other.pairedDevices, pairedDevices) &&
        listEquals(other.discoveredDevices, discoveredDevices) &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    adapterState,
    permissionState,
    availability,
    scanPhase,
    scanOwner,
    isScanning,
    isWorking,
    hasBootstrappedHome,
    homeScanEndsAt,
    pendingBootstrapPrompt,
    lastBootstrapPromptAt,
    connectedDevice,
    Object.hashAll(pairedDevices),
    Object.hashAll(discoveredDevices),
    errorMessage,
  );
}

class BluetoothDomainController extends StateNotifier<BluetoothDomainState> {
  BluetoothDomainController(this.ref)
    : super(const BluetoothDomainState.initial()) {
    _bind();
  }

  final Ref ref;
  StreamSubscription<AdapterState>? _adapterSub;
  Future<void> _queue = Future<void>.value();
  Timer? _homeScanTimer;
  static const Duration _refreshCooldown = Duration(milliseconds: 450);
  static const Duration _startCooldown = Duration(milliseconds: 600);
  static const Duration _homeScanDuration = Duration(seconds: 10);
  static const Duration _connectVerificationTimeout = Duration(seconds: 3);
  static const Duration _connectVerificationInterval = Duration(
    milliseconds: 120,
  );
  DateTime? _lastStopAt;
  bool _deviceViewsRebuildScheduled = false;

  void _bind() {
    _adapterSub = ref
        .read(receiverRepositoryProvider)
        .adapterStateStream
        .listen((adapterState) {
          _setState(state.copyWith(adapterState: adapterState));
          _refreshAvailability();
        });
    _rebuildDeviceViews();
  }

  void rebuildDeviceViews() {
    _rebuildDeviceViews();
  }

  void scheduleDeviceViewsRebuild() {
    if (!mounted || _deviceViewsRebuildScheduled) {
      return;
    }
    _deviceViewsRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deviceViewsRebuildScheduled = false;
      if (!mounted) {
        return;
      }
      _rebuildDeviceViews();
    });
  }

  void syncConnectionState(ReceiverConnectionState connectionState) {
    if (connectionState == ReceiverConnectionState.scanning) {
      _setState(
        state.copyWith(
          scanPhase: BluetoothScanPhase.scanning,
          isScanning: true,
          isWorking: false,
          clearError: true,
        ),
      );
      return;
    }
    if ((state.isScanning || state.scanOwner != BluetoothScanOwner.none) &&
        connectionState == ReceiverConnectionState.disconnected) {
      _homeScanTimer?.cancel();
      _lastStopAt = DateTime.now();
      _setState(
        state.copyWith(
          scanPhase: BluetoothScanPhase.idle,
          scanOwner: BluetoothScanOwner.none,
          isScanning: false,
          isWorking: false,
          clearHomeScanEndsAt: true,
          errorMessage: '蓝牙扫描已停止，请刷新重试。',
        ),
      );
    }
  }

  void _rebuildDeviceViews() {
    final scanned = ref
        .read(receiverDevicesProvider)
        .maybeWhen(
          data: (devices) => devices,
          orElse: () => const <ReceiverScanDevice>[],
        )
        .where(shouldIncludeBluetoothDevice)
        .toList(growable: false);
    final remembered = ref.read(rememberedDevicesProvider);
    final rememberedIds = remembered.map((device) => device.remoteId).toSet();
    final receiverInfo = ref.read(receiverInfoProvider).valueOrNull;
    final connectedRssi = ref.read(connectedRssiProvider).valueOrNull;

    final discoveredDevices = scanned
        .map(
          (device) => ReceiverDeviceView(
            remoteId: device.remoteId,
            name: _preferredDeviceName(
              device.name,
              fallbackRemoteId: device.remoteId,
            ),
            isConnected: device.connected,
            isRemembered: rememberedIds.contains(device.remoteId),
            isOnline: device.rssi > -120,
            rssi: device.rssi,
            scanDevice: device,
          ),
        )
        .toList(growable: false);

    final scannedMap = <String, ReceiverScanDevice>{
      for (final device in scanned) device.remoteId: device,
    };
    String? connectedIdFromScan;
    for (final device in scanned) {
      if (device.connected) {
        connectedIdFromScan = device.remoteId;
        break;
      }
    }
    final connectedId = receiverInfo?.remoteId ?? connectedIdFromScan;
    final pairedDevices = remembered
        .map((entry) {
          final scan = scannedMap[entry.remoteId];
          final isConnected =
              scan?.connected == true || connectedId == entry.remoteId;
          final rssi = isConnected ? (connectedRssi ?? scan?.rssi) : scan?.rssi;
          return ReceiverDeviceView(
            remoteId: entry.remoteId,
            name: entry.name,
            isConnected: isConnected,
            isRemembered: true,
            isOnline: isConnected || (scan?.rssi ?? -127) > -120,
            rssi: rssi,
            scanDevice: scan,
          );
        })
        .toList(growable: false);
    ReceiverDeviceView? connectedDevice;
    if (connectedId != null) {
      connectedDevice = pairedDevices.cast<ReceiverDeviceView?>().firstWhere(
        (device) => device?.remoteId == connectedId,
        orElse: () => null,
      );

      final scannedConnected = discoveredDevices
          .cast<ReceiverDeviceView?>()
          .firstWhere(
            (device) => device?.remoteId == connectedId,
            orElse: () => null,
          );

      if (connectedDevice == null && scannedConnected != null) {
        connectedDevice = scannedConnected;
      } else if (connectedDevice != null && scannedConnected != null) {
        connectedDevice = ReceiverDeviceView(
          remoteId: connectedDevice.remoteId,
          name: _preferredDeviceName(
            scannedConnected.name,
            rememberedName: connectedDevice.name,
            fallbackRemoteId: connectedDevice.remoteId,
          ),
          isConnected: true,
          isRemembered: connectedDevice.isRemembered,
          isOnline: scannedConnected.isOnline,
          rssi: connectedRssi ?? scannedConnected.rssi ?? connectedDevice.rssi,
          scanDevice: scannedConnected.scanDevice ?? connectedDevice.scanDevice,
        );
      }

      connectedDevice ??= ReceiverDeviceView(
        remoteId: connectedId,
        name: _preferredDeviceName(
          scannedMap[connectedId]?.name,
          rememberedName: remembered
              .cast<RememberedReceiver?>()
              .firstWhere(
                (device) => device?.remoteId == connectedId,
                orElse: () => null,
              )
              ?.name,
          fallbackRemoteId: connectedId,
        ),
        isConnected: true,
        isRemembered: rememberedIds.contains(connectedId),
        isOnline: true,
        rssi: connectedRssi ?? scannedMap[connectedId]?.rssi,
        scanDevice: scannedMap[connectedId],
      );
    }
    _setState(
      state.copyWith(
        pairedDevices: pairedDevices,
        discoveredDevices: discoveredDevices,
        connectedDevice: connectedDevice,
      ),
    );
  }

  Future<void> refreshEnvironment() async {
    await refreshPermissionState();
    _refreshAvailability();
  }

  Future<BluetoothAvailability> ensureReadyForEntry() async {
    await refreshEnvironment();
    return state.availability;
  }

  Future<void> bootstrapHomeBluetooth() async {
    await _enqueue(() async {
      if (!mounted) {
        return;
      }
      _setState(state.copyWith(hasBootstrappedHome: true, clearError: true));
      final granted = await _requestBluetoothPermissionsForBootstrap();
      if (!mounted) {
        return;
      }
      if (!granted) {
        _queueBootstrapPrompt(BluetoothBootstrapPrompt.permissionRequired);
        return;
      }
      _refreshAvailability();
      if (state.availability == BluetoothAvailability.bluetoothOff) {
        _queueBootstrapPrompt(BluetoothBootstrapPrompt.bluetoothOff);
        return;
      }
      if (state.availability == BluetoothAvailability.ready) {
        await _startScanSession(BluetoothScanOwner.home);
      }
    });
  }

  Future<void> retryHomeBluetooth() async {
    await bootstrapHomeBluetooth();
  }

  Future<void> refreshPermissionState() async {
    final permissionState = await _readPermissionState();
    _setState(state.copyWith(permissionState: permissionState));
  }

  Future<bool> requestPermissionOrOpenSettings() async {
    final permissions = _permissionsForPlatform();
    if (permissions.isEmpty) {
      _setState(
        state.copyWith(
          permissionState: BluetoothPermissionState.unsupported,
          availability: BluetoothAvailability.unsupported,
        ),
      );
      return false;
    }
    final results = await permissions.request();
    final granted = results.values.every((status) => status.isGranted);
    if (granted) {
      _setState(
        state.copyWith(
          permissionState: BluetoothPermissionState.granted,
          clearError: true,
        ),
      );
      _refreshAvailability();
      return true;
    }
    await openAppSettings();
    await refreshPermissionState();
    _refreshAvailability();
    return false;
  }

  Future<void> openBluetoothSettings() async {
    await ref.read(receiverRepositoryProvider).turnOnAdapter();
  }

  Future<void> clearBootstrapPrompt() async {
    _setState(
      state.copyWith(pendingBootstrapPrompt: BluetoothBootstrapPrompt.none),
    );
  }

  Future<bool> startHomeScanSession() {
    return _enqueue(() => _startScanSession(BluetoothScanOwner.home));
  }

  Future<bool> startListScanSession() {
    return _enqueue(() => _startScanSession(BluetoothScanOwner.listPage));
  }

  Future<bool> stopScan({
    BluetoothScanOwner? sessionOwner,
    bool force = false,
  }) {
    return _enqueue(
      () => _stopInternal(sessionOwner: sessionOwner, force: force),
    );
  }

  Future<bool> refreshScan() {
    return _enqueue(() async {
      final stopped = await _stopInternal(force: true);
      if (!stopped || !mounted) {
        return false;
      }
      _setState(
        state.copyWith(
          scanPhase: BluetoothScanPhase.cooling,
          scanOwner: BluetoothScanOwner.none,
          isScanning: false,
          isWorking: true,
          clearHomeScanEndsAt: true,
        ),
      );
      await Future<void>.delayed(_refreshCooldown);
      if (!mounted) {
        return false;
      }
      return _startScanSession(BluetoothScanOwner.listPage);
    });
  }

  Future<bool> connect(String remoteId) async {
    final target = state.discoveredDevices
        .where((d) => d.remoteId == remoteId)
        .cast<ReceiverDeviceView?>()
        .firstOrNull;
    final pairedTarget = state.pairedDevices
        .where((d) => d.remoteId == remoteId)
        .cast<ReceiverDeviceView?>()
        .firstOrNull;
    final rememberedTarget = target ?? pairedTarget;
    final repo = ref.read(receiverRepositoryProvider);

    try {
      await repo.connect(remoteId);
    } catch (_) {
      final connectedAfterError = await _waitForConnectedDevice(remoteId);
      if (!connectedAfterError) {
        _setState(state.copyWith(errorMessage: '连接设备失败，请重试。'));
        return false;
      }
    }

    final connected = await _waitForConnectedDevice(remoteId);
    if (!connected) {
      _setState(state.copyWith(errorMessage: '连接设备失败，请重试。'));
      return false;
    }

    final rememberedDevice =
        rememberedTarget?.scanDevice ??
        ReceiverScanDevice(
          remoteId: remoteId,
          name: _preferredDeviceName(
            rememberedTarget?.name,
            rememberedName: rememberedTarget?.name,
            fallbackRemoteId: remoteId,
          ),
          rssi: rememberedTarget?.rssi ?? -127,
          connected: true,
        );
    await ref
        .read(rememberedDevicesProvider.notifier)
        .rememberDevice(rememberedDevice);
    _rebuildDeviceViews();
    return true;
  }

  Future<bool> _waitForConnectedDevice(String remoteId) async {
    if (_isConnectedTo(remoteId)) {
      return true;
    }
    final deadline = DateTime.now().add(_connectVerificationTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_connectVerificationInterval);
      if (_isConnectedTo(remoteId)) {
        return true;
      }
    }
    return _isConnectedTo(remoteId);
  }

  bool _isConnectedTo(String remoteId) {
    final connected = state.connectedDevice;
    if (connected != null &&
        connected.remoteId == remoteId &&
        connected.isConnected) {
      return true;
    }
    final discoveredConnected = state.discoveredDevices
        .where((device) => device.remoteId == remoteId && device.isConnected)
        .isNotEmpty;
    if (discoveredConnected) {
      return true;
    }
    final pairedConnected = state.pairedDevices
        .where((device) => device.remoteId == remoteId && device.isConnected)
        .isNotEmpty;
    if (pairedConnected) {
      return true;
    }
    final info = ref.read(receiverInfoProvider).valueOrNull;
    return info?.remoteId == remoteId;
  }

  Future<bool> disconnect() async {
    try {
      await ref.read(receiverRepositoryProvider).disconnect();
      return true;
    } catch (_) {
      _setState(state.copyWith(errorMessage: '断开连接失败，请重试。'));
      return false;
    }
  }

  Future<void> removeRememberedDevice(String remoteId) async {
    await ref.read(rememberedDevicesProvider.notifier).removeDevice(remoteId);
  }

  void clearError() {
    _setState(state.copyWith(clearError: true));
  }

  Future<void> ensureScanStopped() async {
    await stopScan(force: true);
  }

  Future<bool> _startScanSession(BluetoothScanOwner owner) async {
    if (state.isScanning) {
      if (state.scanOwner == BluetoothScanOwner.home &&
          owner == BluetoothScanOwner.home) {
        _scheduleHomeScanStop();
      }
      return true;
    }
    return _startInternal(owner);
  }

  Future<bool> _startInternal(BluetoothScanOwner owner) async {
    if (!mounted) {
      return false;
    }
    _homeScanTimer?.cancel();
    _setState(
      state.copyWith(
        scanPhase: BluetoothScanPhase.starting,
        scanOwner: owner,
        isWorking: true,
        homeScanEndsAt: owner == BluetoothScanOwner.home
            ? DateTime.now().add(_homeScanDuration)
            : null,
        clearHomeScanEndsAt: owner != BluetoothScanOwner.home,
        clearError: true,
      ),
    );
    try {
      await _waitForScanCooldown();
      await ref.read(receiverRepositoryProvider).startScan();
      _setState(
        state.copyWith(
          scanPhase: BluetoothScanPhase.scanning,
          scanOwner: owner,
          isScanning: true,
          isWorking: false,
          clearError: true,
        ),
      );
      if (owner == BluetoothScanOwner.home) {
        _scheduleHomeScanStop();
      }
      return true;
    } catch (error) {
      _lastStopAt = DateTime.now();
      _setState(
        state.copyWith(
          scanPhase: BluetoothScanPhase.error,
          scanOwner: BluetoothScanOwner.none,
          isScanning: false,
          isWorking: false,
          clearHomeScanEndsAt: true,
          errorMessage: _scanStartErrorMessage(error),
        ),
      );
      return false;
    }
  }

  Future<bool> _stopInternal({
    BluetoothScanOwner? sessionOwner,
    bool force = false,
  }) async {
    if (!mounted) {
      return false;
    }
    if (!force &&
        sessionOwner != null &&
        state.scanOwner != BluetoothScanOwner.none &&
        state.scanOwner != sessionOwner) {
      return true;
    }
    if (!state.isScanning) {
      _homeScanTimer?.cancel();
      _setState(
        state.copyWith(
          scanPhase: BluetoothScanPhase.idle,
          scanOwner: BluetoothScanOwner.none,
          isWorking: false,
          clearHomeScanEndsAt: true,
          clearError: true,
        ),
      );
      return true;
    }
    _setState(
      state.copyWith(scanPhase: BluetoothScanPhase.stopping, isWorking: true),
    );
    try {
      await ref.read(receiverRepositoryProvider).stopScan();
      _homeScanTimer?.cancel();
      _lastStopAt = DateTime.now();
      _setState(
        state.copyWith(
          scanPhase: BluetoothScanPhase.idle,
          scanOwner: BluetoothScanOwner.none,
          isScanning: false,
          isWorking: false,
          clearHomeScanEndsAt: true,
          clearError: true,
        ),
      );
      return true;
    } catch (_) {
      _homeScanTimer?.cancel();
      _setState(
        state.copyWith(
          scanPhase: BluetoothScanPhase.error,
          scanOwner: BluetoothScanOwner.none,
          isScanning: false,
          isWorking: false,
          clearHomeScanEndsAt: true,
          errorMessage: '扫描停止失败，请稍后重试。',
        ),
      );
      return false;
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        final result = await task();
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } catch (error, stack) {
        if (!completer.isCompleted) {
          completer.completeError(error, stack);
        }
      }
    });
    return completer.future;
  }

  Future<void> _waitForScanCooldown() async {
    final lastStopAt = _lastStopAt;
    if (lastStopAt == null) {
      return;
    }
    final elapsed = DateTime.now().difference(lastStopAt);
    final remaining = _startCooldown - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  String _scanStartErrorMessage(Object error) {
    final message = '$error';
    if (message.contains('APPLICATION_REGISTRATION_FAILED')) {
      return '蓝牙扫描初始化失败，请稍后重试。';
    }
    return '扫描启动失败，请稍后重试。';
  }

  Future<bool> _requestBluetoothPermissionsForBootstrap() async {
    await refreshPermissionState();
    if (state.permissionState == BluetoothPermissionState.granted) {
      return true;
    }
    final permissions = _permissionsForPlatform();
    if (permissions.isEmpty) {
      return false;
    }
    final results = await permissions.request();
    final granted = results.values.every((status) => status.isGranted);
    await refreshPermissionState();
    return granted;
  }

  Future<BluetoothPermissionState> _readPermissionState() async {
    final permissions = _permissionsForPlatform();
    if (permissions.isEmpty) {
      return BluetoothPermissionState.unsupported;
    }
    var hasDenied = false;
    for (final permission in permissions) {
      final status = await permission.status;
      if (status.isGranted) {
        continue;
      }
      if (status.isPermanentlyDenied) {
        return BluetoothPermissionState.permanentlyDenied;
      }
      hasDenied = true;
    }
    if (!hasDenied) {
      return BluetoothPermissionState.granted;
    }
    return BluetoothPermissionState.denied;
  }

  void _refreshAvailability() {
    final adapter = state.adapterState;
    final permission = state.permissionState;
    final availability = switch (adapter) {
      AdapterState.on => switch (permission) {
        BluetoothPermissionState.granted => BluetoothAvailability.ready,
        BluetoothPermissionState.unknown => BluetoothAvailability.unknown,
        BluetoothPermissionState.unsupported =>
          BluetoothAvailability.unsupported,
        _ => BluetoothAvailability.permissionRequired,
      },
      AdapterState.unknown ||
      AdapterState.turningOn => BluetoothAvailability.unknown,
      AdapterState.unsupported => BluetoothAvailability.unsupported,
      _ => BluetoothAvailability.bluetoothOff,
    };
    _setState(state.copyWith(availability: availability));
  }

  void _queueBootstrapPrompt(BluetoothBootstrapPrompt prompt) {
    _setState(
      state.copyWith(
        pendingBootstrapPrompt: prompt,
        lastBootstrapPromptAt: DateTime.now(),
      ),
    );
  }

  void _scheduleHomeScanStop() {
    _homeScanTimer?.cancel();
    _homeScanTimer = Timer(_homeScanDuration, () {
      unawaited(stopScan(sessionOwner: BluetoothScanOwner.home));
    });
  }

  List<Permission> _permissionsForPlatform() {
    if (Platform.isAndroid) {
      return <Permission>[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ];
    }
    if (Platform.isIOS) {
      return <Permission>[Permission.bluetooth];
    }
    return <Permission>[];
  }

  String _preferredDeviceName(
    String? currentName, {
    String? rememberedName,
    required String fallbackRemoteId,
  }) {
    final scanName = currentName?.trim() ?? '';
    if (scanName.isNotEmpty && scanName != fallbackRemoteId) {
      return scanName;
    }
    final historyName = rememberedName?.trim() ?? '';
    if (historyName.isNotEmpty) {
      return historyName;
    }
    if (scanName.isNotEmpty) {
      return scanName;
    }
    return fallbackRemoteId;
  }

  void _setState(BluetoothDomainState next) {
    if (!mounted || next == state) {
      return;
    }
    state = next;
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _homeScanTimer?.cancel();
    unawaited(ref.read(receiverRepositoryProvider).stopScan());
    super.dispose();
  }
}

final bluetoothDomainControllerProvider =
    StateNotifierProvider.autoDispose<
      BluetoothDomainController,
      BluetoothDomainState
    >((ref) {
      final controller = BluetoothDomainController(ref);
      ref.listen<AsyncValue<List<ReceiverScanDevice>>>(
        receiverDevicesProvider,
        (_, __) {
          controller.scheduleDeviceViewsRebuild();
        },
      );
      ref.listen<List<RememberedReceiver>>(rememberedDevicesProvider, (_, __) {
        controller.scheduleDeviceViewsRebuild();
      });
      ref.listen<AsyncValue<ReceiverInfo?>>(receiverInfoProvider, (_, __) {
        controller.scheduleDeviceViewsRebuild();
      });
      ref.listen<AsyncValue<int?>>(connectedRssiProvider, (_, __) {
        controller.scheduleDeviceViewsRebuild();
      });
      ref.listen<AsyncValue<ReceiverConnectionState>>(
        receiverConnectionProvider,
        (_, next) {
          final connectionState = next.valueOrNull;
          if (connectionState != null) {
            controller.syncConnectionState(connectionState);
          }
        },
      );
      return controller;
    });

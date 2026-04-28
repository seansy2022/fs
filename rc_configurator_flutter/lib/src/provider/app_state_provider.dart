import 'dart:async';
import 'dart:collection';

import 'package:flutter_blue_plus/flutter_blue_plus.dart'
    show
        BluetoothAdapterState,
        BluetoothConnectionState,
        FlutterBluePlus,
        OnConnectionStateChangedEvent;
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBindingObserver, WidgetsFlutterBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ble/rc_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rc_configurator_flutter/src/lib/link/link_providers.dart';
import 'package:rc_configurator_flutter/src/lib/protocol/protocol_adapter.dart';
import '../types.dart';
import 'app_state_models.dart';
import 'control_mapping_options.dart';
import 'control_mapping_reset_config.dart';
import 'control_mapping_reset_defaults.dart';

final rcAppStateProvider = NotifierProvider<RcAppController, RcAppState>(
  RcAppController.new,
);

final linkSyncProvider = Provider<RcAppController>((ref) {
  return ref.read(rcAppStateProvider.notifier);
});

//MG11
const _bluetoothNamePrefix = 'MG11';
const _intentDebounceDelay = Duration(milliseconds: 500);
const _mixingIntentDebounceDelay = Duration(milliseconds: 400);
const _scanDuration = Duration(seconds: 20);
const _connectTimeout = Duration(seconds: 10);
const _enableRealtimeReadPolling = false;
const _realtimeReadInterval = Duration(milliseconds: 200);
const _realtimeReadFailureBackoff = Duration(milliseconds: 700);
const _screenReadFailedMessage = '读取设备数据失败，请重试';
const _connectTimeoutMessage = '连接超时，请重试';
const _connectRetryCount = 2;
const _connectRetryDelay = Duration(milliseconds: 900);
const _modelNamesPrefsKey = 'rc_model_names';
const _lastConnectedBluetoothMacPrefsKey = 'rc_last_connected_bluetooth_mac';
const _sessionReadyTimeout = Duration(seconds: 2);
const _sessionReadyPoll = Duration(milliseconds: 80);
const _screenRefreshDedupWindow = Duration(milliseconds: 200);
const _controlMappingReadChannels = <String>[
  'CH11',
  'CH3',
  'CH4',
  'CH5',
  'CH6',
  'CH7',
  'CH8',
  'CH9',
  'CH10',
];
const _protocolRequestPolicy = BluetoothRequestPolicy(
  defaultTimeout: Duration(milliseconds: 900),
  controlMappingWriteTimeout: Duration(milliseconds: 1200),
  readTimeout: Duration(milliseconds: 1500),
  maxRetries: 1,
  readMaxRetries: 1,
  readTimeoutCooldown: Duration(milliseconds: 500),
);

enum ScreenRefreshResult { success, needConnection, needSession, readFailed }

enum _SessionTaskPriority { high, normal, low }

class _SessionTask {
  _SessionTask({required this.task, required this.completer});

  final Future<void> Function() task;
  final Completer<void> completer;
}

class RcAppController extends Notifier<RcAppState> with WidgetsBindingObserver {
  StreamSubscription<List<BluetoothScanDevice>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
  StreamSubscription<OnConnectionStateChangedEvent>? _connectionStateSub;
  StreamSubscription? _frameSub;
  BluetoothProtocolClient? _client;
  Future<void>? _openingSessionTask;
  final ListQueue<_SessionTask> _highPrioritySessionTasks =
      ListQueue<_SessionTask>();
  final ListQueue<_SessionTask> _normalPrioritySessionTasks =
      ListQueue<_SessionTask>();
  final ListQueue<_SessionTask> _lowPrioritySessionTasks =
      ListQueue<_SessionTask>();
  bool _sessionTaskRunnerActive = false;
  Timer? _intentDebounceTimer;
  Timer? _scanTimer;
  Timer? _realtimeReadTimer;
  DateTime? _realtimeReadBackoffUntil;
  DateTime? _realtimeReadLastErrorLogAt;
  RcAppIntent? _pendingDebouncedIntent;
  bool _realtimeReadInFlight = false;
  bool _blockWritesUntilReverseRead = false;
  String? _pinnedControlMappingChannel;
  bool _connectRetryInProgress = false;
  final Map<String, int> _deviceIds = <String, int>{};
  int _nextId = 1;
  String? _lastConnectedBluetoothMac;
  bool _autoConnectingLastDevice = false;
  String? _connectingBluetoothMac;
  bool _resumeRealtimeAfterForeground = false;
  final Map<Screen, DateTime> _lastScreenRefreshAt = <Screen, DateTime>{};
  final Map<Screen, Future<ScreenRefreshResult>> _screenRefreshInFlight =
      <Screen, Future<ScreenRefreshResult>>{};

  LinkTransport get _transport => ref.read(linkTransportProvider);
  ProtocolAdapter get _adapter => ref.read(protocolAdapterProvider);

  @override
  RcAppState build() {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    binding.addObserver(this);
    ref.onDispose(() {
      binding.removeObserver(this);
      unawaited(_dispose());
    });
    _bindBleAdapterState();
    _bindBleConnectionState();
    unawaited(_restoreModelNames());
    unawaited(_restoreLastConnectedBluetoothMac());
    return RcAppState.initial();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_transport.type != LinkType.ble) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeAfterForeground());
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _resumeRealtimeAfterForeground = _realtimeReadTimer != null;
      _stopRealtimeReadLoop();
    }
  }

  Future<void> _dispose() async {
    _clearIntentDebounce();
    _scanTimer?.cancel();
    _stopRealtimeReadLoop();
    await _scanSub?.cancel();
    await _adapterStateSub?.cancel();
    await _connectionStateSub?.cancel();
    await _frameSub?.cancel();
    await _client?.dispose();
  }

  Future<void> _resumeAfterForeground() async {
    if (state.bluetooth.isConnected) {
      if (!_resumeRealtimeAfterForeground) return;
      _resumeRealtimeAfterForeground = false;
      final ready = await _waitSessionReady();
      if (ready && state.bluetooth.isConnected) {
        _startRealtimeReadLoop();
      }
      return;
    }
    _resumeRealtimeAfterForeground = false;
    final hasLast =
        _lastConnectedBluetoothMac != null &&
        _lastConnectedBluetoothMac!.isNotEmpty;
    if (!hasLast) return;
    if (state.bluetooth.isConnecting || state.bluetooth.isScanning) return;
    startScan();
  }

  void _bindBleAdapterState() {
    if (_transport.type != LinkType.ble) return;
    unawaited(_adapterStateSub?.cancel());
    _adapterStateSub = FlutterBluePlus.adapterState.listen((adapterState) {
      if (adapterState == BluetoothAdapterState.on) return;
      if (!state.bluetooth.isConnected) return;
      final mac = state.bluetooth.connectedDeviceMac;
      if (mac == null || mac.isEmpty) return;
      unawaited(_disconnect(mac, clearLastConnected: true));
    }, onError: _onError);
  }

  void _bindBleConnectionState() {
    if (_transport.type != LinkType.ble) return;
    unawaited(_connectionStateSub?.cancel());
    _connectionStateSub = FlutterBluePlus.events.onConnectionStateChanged
        .listen(_onBleConnectionChanged, onError: _onError);
  }

  void _onBleConnectionChanged(OnConnectionStateChangedEvent event) {
    final eventMac = event.device.remoteId.str.toLowerCase();
    if (event.connectionState == BluetoothConnectionState.connected) {
      final connectingMac = _connectingBluetoothMac?.toLowerCase();
      if (connectingMac != null && connectingMac != eventMac) return;
      if (connectingMac == null) {
        final currentMac = state.bluetooth.connectedDeviceMac;
        if (currentMac == null || currentMac.toLowerCase() != eventMac) return;
      }
      _connectingBluetoothMac = null;
      unawaited(_stopScanQuietly());
      _setBluetooth(
        state.bluetooth.copyWith(
          devices: _markConnectedByMac(
            state.bluetooth.devices,
            event.device.remoteId.str,
          ),
          isScanning: false,
          isConnecting: false,
          isConnected: true,
          connectedDeviceMac: event.device.remoteId.str,
          clearConnectingDeviceMac: true,
          clearConnectingStartedAt: true,
          clearErrorMessage: true,
        ),
      );
      unawaited(_ensureSessionOpened());
      return;
    }
    if (event.connectionState != BluetoothConnectionState.disconnected) return;
    final connectingMac = _connectingBluetoothMac?.toLowerCase();
    if (connectingMac != null && connectingMac == eventMac) {
      if (_connectRetryInProgress) {
        return;
      }
      _stopRealtimeReadLoop();
      _connectingBluetoothMac = null;
      _setBluetooth(
        state.bluetooth.copyWith(
          devices: _markConnected(state.bluetooth.devices, null),
          isConnecting: false,
          clearConnectingDeviceMac: true,
          clearConnectingStartedAt: true,
        ),
      );
      return;
    }
    final currentMac = state.bluetooth.connectedDeviceMac;
    if (currentMac == null || currentMac.isEmpty) return;
    if (eventMac != currentMac.toLowerCase()) return;
    _connectingBluetoothMac = null;
    unawaited(_disconnect(currentMac));
  }

  void dispatch(RcAppIntent intent) {
    state = _reduce(state, intent);
    final stateAfterReduce = state;
    if (intent is ModelRenamedIntent) {
      unawaited(_persistModelNames(state.models));
    }
    if (!state.bluetooth.isConnected) return;
    if (intent is MixingSettingsUpdatedIntent) {
      _queueIntentDebounce(intent, delay: _mixingIntentDebounceDelay);
      return;
    }
    if (_shouldDebounceIntent(intent)) {
      _queueIntentDebounce(intent);
      return;
    }
    _clearIntentDebounce();
    unawaited(
      _enqueueSession(() async {
        await _syncIntent(intent, source: stateAfterReduce);
      }, priority: _SessionTaskPriority.high),
    );
  }

  void startScan() => unawaited(_startScan());

  void toggleConnection(int id) => unawaited(_toggleConnection(id));

  Future<bool> resetDefaultsForScreen(
    Screen screen, {
    bool resetAllMixingModes = false,
  }) async {
    final writes = <(RcAppIntent, RcAppState)>[];
    final preControlMappingWrites = <List<int>>[];
    var nextState = state;

    if (screen == Screen.reverse) {
      final channels = state.channels
          .map((ch) => ch.copyWith(reverse: false))
          .toList(growable: false);
      if (channels.isEmpty) return false;
      nextState = state.copyWith(channels: channels);
      final first = channels.first;
      writes.add((
        ChannelReverseUpdatedIntent(id: first.id, next: first),
        nextState,
      ));
    } else if (screen == Screen.channels) {
      final channels = state.channels
          .map((ch) => ch.copyWith(lLimit: 100, rLimit: 100))
          .toList(growable: false);
      if (channels.isEmpty) return false;
      nextState = state.copyWith(channels: channels);
      final first = channels.first;
      writes.add((
        ChannelTravelUpdatedIntent(id: first.id, next: first),
        nextState,
      ));
    } else if (screen == Screen.subTrim) {
      final channels = state.channels
          .map((ch) => ch.copyWith(offset: 0))
          .toList(growable: false);
      if (channels.isEmpty) return false;
      nextState = state.copyWith(channels: channels);
      final first = channels.first;
      writes.add((SubTrimUpdatedIntent(id: first.id, next: first), nextState));
    } else if (screen == Screen.dualRate) {
      final channels = state.channels
          .map((ch) => ch.copyWith(dualRate: 100))
          .toList(growable: false);
      if (channels.isEmpty) return false;
      nextState = state.copyWith(channels: channels);
      final first = channels.first;
      writes.add((DualRateUpdatedIntent(id: first.id, next: first), nextState));
    } else if (screen == Screen.curve) {
      nextState = state.copyWith(
        curve: state.curve.copyWith(curveValue: 0),
        protocol: state.protocol.copyWith(curveValues: const [0, 0, 0]),
      );
      writes.add((CurveSelectedIntent(nextState.curve.activeCurve), nextState));
    } else if (screen == Screen.controlMapping) {
      preControlMappingWrites.addAll(controlMappingResetSeedPayloads);
      final currentChannel = state.controlMapping.channel;
      final defaults = controlMappingResetDefaults();
      if (defaults.isEmpty) return false;
      var working = state;
      for (final next in defaults) {
        working = _reduce(working, ControlMappingUpdatedIntent(next));
      }
      preControlMappingWrites.addAll(
        controlMappingResetConfigs.map((e) => e.payload),
      );
      final current = defaults.where((e) => e.channel == currentChannel);
      final selected = current.isNotEmpty ? current.first : defaults.last;
      nextState = working.copyWith(controlMapping: selected);
    } else if (screen == Screen.modelSelection) {
      if (state.models.isEmpty) return false;
      final firstId = state.models.first.id;
      final models = state.models
          .map((m) => m.copyWith(active: m.id == firstId))
          .toList(growable: false);
      nextState = state.copyWith(models: models);
      writes.add((ModelSelectedIntent(firstId), nextState));
    } else if (screen == Screen.failsafe) {
      final channels = state.channels
          .map((ch) => ch.copyWith(failsafeActive: false, failsafeValue: 0))
          .toList(growable: false);
      if (channels.isEmpty) return false;
      nextState = state.copyWith(channels: channels);
      final first = channels.first;
      writes.add((FailsafeUpdatedIntent(id: first.id, next: first), nextState));
    } else if (screen == Screen.radioSettings) {
      const next = RadioSettings(
        backlightTime: 10,
        idleAlarm: 600,
        atmosphereLight: true,
      );
      nextState = state.copyWith(radioSettings: next);
      writes.add((RadioSettingsUpdatedIntent(next), nextState));
    } else if (screen == Screen.mixing) {
      if (resetAllMixingModes) {
        final originalMode = state.mixingSettings.activeMode;
        var working = state;
        for (final mode in const ['4WS', 'TRACK', 'DRIVE', 'BRAKE']) {
          if (mode == '4WS') {
            working = working.copyWith(
              protocol: working.protocol.copyWith(
                fourWheelSteer: const FourWheelSteerSnapshot(),
              ),
            );
          }
          if (mode == 'TRACK') {
            working = working.copyWith(
              protocol: working.protocol.copyWith(
                trackMixing: const TrackMixingSnapshot(),
              ),
            );
          }
          if (mode == 'DRIVE') {
            working = working.copyWith(
              protocol: working.protocol.copyWith(
                driveMixing: const DriveMixingSnapshot(),
              ),
            );
          }
          if (mode == 'BRAKE') {
            working = working.copyWith(
              protocol: working.protocol.copyWith(
                brakeMixing: const BrakeMixingSnapshot(),
              ),
            );
          }
          final defaults = switch (mode) {
            '4WS' => working.mixingSettings.copyWith(
              activeMode: mode,
              enabled: false,
              selectedChannel: 'CH3',
              ratio: 100,
              direction: '4WS_FRONT_SAME',
            ),
            'TRACK' => working.mixingSettings.copyWith(
              activeMode: mode,
              enabled: false,
              ratio: 100,
              direction: 'SAME',
            ),
            'DRIVE' => working.mixingSettings.copyWith(
              activeMode: mode,
              enabled: false,
              selectedChannel: 'CH3',
              ratio: 0,
              direction: 'REAR',
              driveRatioSelectedSide: 'R',
            ),
            'BRAKE' => working.mixingSettings.copyWith(
              activeMode: mode,
              enabled: false,
              selectedChannel: 'CH3',
              ratio: 100,
              curve: 0,
            ),
            _ => working.mixingSettings.copyWith(
              activeMode: mode,
              enabled: false,
            ),
          };
          final intent = MixingSettingsUpdatedIntent(defaults);
          working = _reduce(working, intent);
          writes.add((intent, working));
        }
        if (originalMode.isEmpty) {
          nextState = working;
        } else {
          final restored = originalMode == '4WS'
              ? working.mixingSettings.copyWith(
                  activeMode: originalMode,
                  selectedChannel: 'CH3',
                  ratio: 100,
                  direction: '4WS_FRONT_SAME',
                )
              : originalMode == 'TRACK'
              ? working.mixingSettings.copyWith(
                  activeMode: originalMode,
                  ratio: 100,
                  direction: 'SAME',
                )
              : originalMode == 'DRIVE'
              ? working.mixingSettings.copyWith(
                  activeMode: originalMode,
                  selectedChannel: 'CH3',
                  ratio: 0,
                  direction: 'REAR',
                  driveRatioSelectedSide: 'R',
                )
              : originalMode == 'BRAKE'
              ? working.mixingSettings.copyWith(
                  activeMode: originalMode,
                  selectedChannel: 'CH3',
                  ratio: 100,
                  curve: 0,
                )
              : working.mixingSettings.copyWith(activeMode: originalMode);
          nextState = working.copyWith(mixingSettings: restored);
        }
      } else {
        final mode = state.mixingSettings.activeMode.isEmpty
            ? '4WS'
            : state.mixingSettings.activeMode;
        var working = state;
        if (mode == '4WS') {
          working = working.copyWith(
            protocol: working.protocol.copyWith(
              fourWheelSteer: const FourWheelSteerSnapshot(),
            ),
          );
        }
        if (mode == 'TRACK') {
          working = working.copyWith(
            protocol: working.protocol.copyWith(
              trackMixing: const TrackMixingSnapshot(),
            ),
          );
        }
        if (mode == 'DRIVE') {
          working = working.copyWith(
            protocol: working.protocol.copyWith(
              driveMixing: const DriveMixingSnapshot(),
            ),
          );
        }
        if (mode == 'BRAKE') {
          working = working.copyWith(
            protocol: working.protocol.copyWith(
              brakeMixing: const BrakeMixingSnapshot(),
            ),
          );
        }
        final defaults = switch (mode) {
          '4WS' => working.mixingSettings.copyWith(
            activeMode: mode,
            enabled: false,
            selectedChannel: 'CH3',
            ratio: 100,
            direction: '4WS_FRONT_SAME',
          ),
          'TRACK' => working.mixingSettings.copyWith(
            activeMode: mode,
            enabled: false,
            ratio: 100,
            direction: 'SAME',
          ),
          'DRIVE' => working.mixingSettings.copyWith(
            activeMode: mode,
            enabled: false,
            selectedChannel: 'CH3',
            ratio: 0,
            direction: 'REAR',
            driveRatioSelectedSide: 'R',
          ),
          'BRAKE' => working.mixingSettings.copyWith(
            activeMode: mode,
            enabled: false,
            selectedChannel: 'CH3',
            ratio: 100,
            curve: 0,
          ),
          _ => working.mixingSettings.copyWith(
            activeMode: mode,
            enabled: false,
          ),
        };
        final intent = MixingSettingsUpdatedIntent(defaults);
        working = _reduce(working, intent);
        writes.add((intent, working));
        nextState = working;
      }
    } else {
      return false;
    }

    state = nextState;
    if (!state.bluetooth.isConnected ||
        (writes.isEmpty && preControlMappingWrites.isEmpty)) {
      return false;
    }

    _clearIntentDebounce();
    final ready = await _waitSessionReady();
    if (!ready) {
      _onError(_screenReadFailedMessage);
      return false;
    }
    final wasRealtimeRunning = _realtimeReadTimer != null;
    if (wasRealtimeRunning) {
      _stopRealtimeReadLoop();
    }
    var success = true;
    try {
      await _enqueueSession(() async {
        if (preControlMappingWrites.isNotEmpty) {
          final client = _client;
          if (client == null) {
            success = false;
            return;
          }
          for (final payload in preControlMappingWrites) {
            try {
              final ack = await client.writeCommand(
                BluetoothCommand.controlMapping,
                payload,
              );
              if (!ack.isSuccess) {
                _onError(
                  StateError('controlMapping seed ack failed: ${ack.code}'),
                );
                success = false;
                return;
              }
            } catch (error) {
              _onError(error);
              success = false;
              return;
            }
          }
        }
        for (final write in writes) {
          final ok = await _syncIntent(write.$1, source: write.$2);
          if (!ok) {
            success = false;
            break;
          }
        }
      }, priority: _SessionTaskPriority.high);
      return success;
    } finally {
      if (wasRealtimeRunning && state.bluetooth.isConnected) {
        _startRealtimeReadLoop();
      }
    }
  }

  Future<bool> refreshForScreen(Screen screen) async {
    return (await refreshForScreenWithStatus(screen)) ==
        ScreenRefreshResult.success;
  }

  Future<ScreenRefreshResult> refreshForScreenWithStatus(Screen screen) async {
    if (!state.bluetooth.isConnected) {
      return ScreenRefreshResult.needConnection;
    }
    final inFlight = _screenRefreshInFlight[screen];
    if (inFlight != null) {
      return inFlight;
    }
    final ready = await _waitSessionReady();
    if (!ready) {
      return ScreenRefreshResult.needSession;
    }
    final lastRefreshAt = _lastScreenRefreshAt[screen];
    final now = DateTime.now();
    if (lastRefreshAt != null &&
        now.difference(lastRefreshAt) < _screenRefreshDedupWindow) {
      RcLogging.protocol(
        'skip duplicate screen refresh screen=${screen.name}',
        scope: 'RcAppController',
      );
      return ScreenRefreshResult.success;
    }
    _lastScreenRefreshAt[screen] = now;
    final task = _refreshScreen(screen);
    _screenRefreshInFlight[screen] = task;
    try {
      return await task;
    } finally {
      if (identical(_screenRefreshInFlight[screen], task)) {
        _screenRefreshInFlight.remove(screen);
      }
    }
  }

  Future<ScreenRefreshResult> _refreshScreen(Screen screen) async {
    var success = false;
    final wasRealtimeRunning = _realtimeReadTimer != null;
    if (wasRealtimeRunning) {
      _stopRealtimeReadLoop();
    }
    if (screen == Screen.reverse) {
      _blockWritesUntilReverseRead = true;
    }
    try {
      await _enqueueSession(() async {
        success = await _syncReadsForScreen(screen);
      });
      return success
          ? ScreenRefreshResult.success
          : ScreenRefreshResult.readFailed;
    } finally {
      if (wasRealtimeRunning && state.bluetooth.isConnected) {
        _startRealtimeReadLoop();
      }
      if (screen == Screen.reverse) {
        _blockWritesUntilReverseRead = false;
      }
    }
  }

  Future<bool> refreshControlMappingForChannel(String channel) async {
    if (!state.bluetooth.isConnected) return false;
    final ready = await _waitSessionReady();
    if (!ready) {
      _onError(_screenReadFailedMessage);
      return false;
    }
    var success = false;
    final wasRealtimeRunning = _realtimeReadTimer != null;
    if (wasRealtimeRunning) {
      _stopRealtimeReadLoop();
    }
    try {
      await _enqueueSession(() async {
        success = await _syncControlMappingRead(channel: channel);
      });
      return success;
    } finally {
      if (wasRealtimeRunning && state.bluetooth.isConnected) {
        _startRealtimeReadLoop();
      }
    }
  }

  Future<void> _startScan() async {
    await _stopScanQuietly();
    await _scanSub?.cancel();
    _scanSub = _transport.scanResults.listen(_onScan, onError: _onError);
    _setBluetooth(
      state.bluetooth.copyWith(isScanning: true, clearErrorMessage: true),
    );
    try {
      await _transport.startScan();
      _scanTimer?.cancel();
      _scanTimer = Timer(_scanDuration, () {
        unawaited(_stopScanQuietly(updateState: true));
      });
    } catch (error) {
      _setBluetooth(state.bluetooth.copyWith(isScanning: false));
      _onError(error);
    }
  }

  Future<void> _toggleConnection(int id) async {
    final target = _deviceById(id);
    if (target == null) return;
    if (state.bluetooth.isConnecting) return;
    final current = state.bluetooth.connectedDeviceMac;
    if (current == target.mac) {
      _connectingBluetoothMac = null;
      await _disconnect(target.mac, clearLastConnected: true);
      return;
    }
    if (current != null && current.isNotEmpty) {
      await _disconnect(current);
    }
    try {
      _connectingBluetoothMac = target.mac;
      final connectingStartedAt = DateTime.now();
      _setBluetooth(
        state.bluetooth.copyWith(
          isScanning: false,
          isConnecting: true,
          isConnected: false,
          clearConnectedDeviceMac: true,
          connectingDeviceMac: target.mac,
          connectingStartedAt: connectingStartedAt,
          clearErrorMessage: true,
        ),
      );
      await _stopScanQuietly();
      _connectRetryInProgress = true;
      try {
        await _connectWithRetry(target.mac);
      } finally {
        _connectRetryInProgress = false;
      }
      _connectingBluetoothMac = null;
      final connectedDevices = _markConnectedByMac(
        state.bluetooth.devices,
        target.mac,
      );
      _setBluetooth(
        state.bluetooth.copyWith(
          devices: _ensureConnectedDeviceVisible(connectedDevices, target),
          isScanning: false,
          isConnecting: false,
          isConnected: true,
          connectedDeviceMac: target.mac,
          clearConnectingDeviceMac: true,
          clearConnectingStartedAt: true,
          clearErrorMessage: true,
        ),
      );
      unawaited(_persistLastConnectedBluetoothMac(target.mac));
    } catch (error) {
      _connectingBluetoothMac = null;
      await _disconnect(target.mac);
      if (error is TimeoutException) {
        _onError(_connectTimeoutMessage);
        return;
      }
      _onError(error);
    }
  }

  Future<void> _connectWithRetry(String remoteId) async {
    Object? lastError;
    for (var attempt = 0; attempt < _connectRetryCount; attempt++) {
      try {
        await _transport.connect(remoteId).timeout(_connectTimeout);
        await _ensureSessionOpened();
        return;
      } catch (error) {
        lastError = error;
        RcLogging.link(
          'connect attempt ${attempt + 1}/$_connectRetryCount failed: $error',
          scope: 'RcAppController',
        );
        try {
          await _transport.disconnect(remoteId);
        } catch (_) {}
        if (attempt + 1 < _connectRetryCount) {
          await Future<void>.delayed(_connectRetryDelay);
        }
      }
    }
    throw lastError ?? StateError('connect failed');
  }

  Future<void> _disconnect(
    String remoteId, {
    bool clearLastConnected = false,
  }) async {
    _stopRealtimeReadLoop();
    _connectingBluetoothMac = null;
    if (clearLastConnected) {
      unawaited(_clearLastConnectedBluetoothMac());
    }
    _clearIntentDebounce();
    try {
      await _transport.disconnect(remoteId);
    } catch (_) {}
    await _frameSub?.cancel();
    _frameSub = null;
    await _client?.dispose();
    _client = null;
    _openingSessionTask = null;
    _lastScreenRefreshAt.clear();
    _screenRefreshInFlight.clear();
    _setBluetooth(
      state.bluetooth.copyWith(
        devices: _markConnected(state.bluetooth.devices, null),
        isScanning: false,
        isConnecting: false,
        isConnected: false,
        clearConnectingDeviceMac: true,
        clearConnectingStartedAt: true,
        clearConnectedDeviceMac: true,
      ),
    );
  }

  Future<void> _stopScanQuietly({bool updateState = false}) async {
    _scanTimer?.cancel();
    _scanTimer = null;
    try {
      await _transport.stopScan();
    } catch (_) {}
    if (updateState) {
      _setBluetooth(state.bluetooth.copyWith(isScanning: false));
    }
  }

  Future<void> _openSession() async {
    _clearIntentDebounce();
    _stopRealtimeReadLoop();
    await _frameSub?.cancel();
    await _client?.dispose();
    _client = BluetoothProtocolClient(
      channel: _TransportProtocolChannel(_transport),
      policy: _protocolRequestPolicy,
    );
    _frameSub = _client!.frameStream.listen(_onFrame, onError: _onError);
    _startRealtimeReadLoop();
  }

  Future<void> _ensureSessionOpened() async {
    if (_client != null) return;
    final pending = _openingSessionTask;
    if (pending != null) {
      await pending;
      return;
    }
    final task = _openSession();
    _openingSessionTask = task;
    try {
      await task;
    } finally {
      if (identical(_openingSessionTask, task)) {
        _openingSessionTask = null;
      }
    }
  }

  Future<bool> _waitSessionReady() async {
    final deadline = DateTime.now().add(_sessionReadyTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (!state.bluetooth.isConnected) return false;
      if (_client != null) return true;
      await _ensureSessionOpened();
      if (_client != null) return true;
      await Future<void>.delayed(_sessionReadyPoll);
    }
    return _client != null;
  }

  void _startRealtimeReadLoop() {
    _stopRealtimeReadLoop();
    if (!_enableRealtimeReadPolling) return;
    _realtimeReadTimer = Timer.periodic(_realtimeReadInterval, (_) {
      unawaited(_pollRealtimeReads());
    });
    unawaited(_pollRealtimeReads());
  }

  void _stopRealtimeReadLoop() {
    _realtimeReadTimer?.cancel();
    _realtimeReadTimer = null;
    _realtimeReadInFlight = false;
    _realtimeReadBackoffUntil = null;
  }

  Future<void> _pollRealtimeReads() async {
    if (_realtimeReadInFlight || !state.bluetooth.isConnected) return;
    final backoffUntil = _realtimeReadBackoffUntil;
    if (backoffUntil != null && DateTime.now().isBefore(backoffUntil)) return;
    final client = _client;
    if (client == null) return;
    _realtimeReadInFlight = true;
    await _enqueueSession(() async {
      try {
        await client.readCommand(BluetoothCommand.channelDisplay);
        await client.readCommand(BluetoothCommand.telemetryDisplay);
        _realtimeReadBackoffUntil = null;
      } catch (error) {
        final message = error is TimeoutException ? (error.message ?? '') : '';
        final cooldown = message.contains('cooldown');
        _realtimeReadBackoffUntil = DateTime.now().add(
          _realtimeReadFailureBackoff,
        );
        if (!cooldown && _shouldLogRealtimeReadError()) {
          RcLogging.protocol(
            'realtime read failed: $error',
            scope: 'RcAppController',
          );
        }
      } finally {
        _realtimeReadInFlight = false;
      }
    }, priority: _SessionTaskPriority.low);
  }

  bool _shouldLogRealtimeReadError() {
    final now = DateTime.now();
    final last = _realtimeReadLastErrorLogAt;
    if (last != null && now.difference(last) < const Duration(seconds: 3)) {
      return false;
    }
    _realtimeReadLastErrorLogAt = now;
    return true;
  }

  Future<bool> _syncReadsForScreen(Screen screen) {
    if (screen == Screen.mixing) {
      return _syncMixingReads();
    }
    if (screen == Screen.controlMapping) {
      return _syncControlMappingReads();
    }
    final commands = _adapter
        .readCommandsForScreen(screen)
        .toList(growable: false);
    _logSecondaryReadCommands(screen, commands);
    return _syncReadCommands(commands);
  }

  Future<bool> _syncMixingReads() async {
    final client = _client;
    if (client == null) return false;
    const commands = [
      BluetoothCommand.fourWheelSteer,
      BluetoothCommand.trackMixing,
      BluetoothCommand.driveMixing,
      BluetoothCommand.brakeMixing,
    ];
    _logSecondaryReadCommands(Screen.mixing, commands);
    var allSuccess = true;
    for (final command in commands) {
      final success = await _readCommand(client, command, reportFailure: false);
      if (!success) allSuccess = false;
    }
    if (!allSuccess) _onError(_screenReadFailedMessage);
    return allSuccess;
  }

  Future<bool> _syncReadCommands(Iterable<BluetoothCommand> commands) async {
    final client = _client;
    if (client == null) return false;
    for (final command in commands) {
      final success = await _readCommand(client, command);
      if (!success) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _syncControlMappingRead({String? channel}) async {
    final client = _client;
    if (client == null) return false;
    final selectedChannel = channel ?? state.controlMapping.channel;
    final payload = [0, _controlMappingChannelIndex(selectedChannel)];
    _logSecondaryReadCommands(Screen.controlMapping, const [
      BluetoothCommand.controlMapping,
    ]);
    RcLogging.protocol(
      '控件分配读取 channel=$selectedChannel len=0 payload=${RcLogging.hex(payload)}',
      scope: 'RcAppController',
    );
    return _readControlMappingPayload(client, payload, reportFailure: true);
  }

  Future<bool> _syncControlMappingReads() async {
    final client = _client;
    if (client == null) return false;
    const currentChannel = 'CH11';
    _showCachedControlMapping(currentChannel);
    _pinnedControlMappingChannel = currentChannel;
    _logSecondaryReadCommands(Screen.controlMapping, const [
      BluetoothCommand.controlMapping,
    ]);
    var allSuccess = true;
    try {
      for (final channel in _controlMappingReadChannels) {
        final payload = [0, _controlMappingChannelIndex(channel)];
        RcLogging.protocol(
          '控件分配读取 channel=$channel len=0 payload=${RcLogging.hex(payload)}',
          scope: 'RcAppController',
        );
        final success = await _readControlMappingPayload(
          client,
          payload,
          reportFailure: false,
        );
        if (!success) allSuccess = false;
      }
      _showCachedControlMapping(currentChannel);
    } finally {
      _pinnedControlMappingChannel = null;
    }
    if (!allSuccess) _onError(_screenReadFailedMessage);
    return allSuccess;
  }

  void _showCachedControlMapping(String channel) {
    final cached = state.controlMappings[channel];
    if (cached == null) return;
    state = state.copyWith(controlMapping: cached);
  }

  void _logSecondaryReadCommands(
    Screen screen,
    Iterable<BluetoothCommand> commands,
  ) {
    final labels = commands
        .map((e) => '${e.name}(0x${e.id.toRadixString(16).toUpperCase()})')
        .join(', ');
    RcLogging.protocol(
      '打开二级页面 ${screen.name} 读取命令: $labels',
      scope: 'RcAppController',
    );
  }

  Future<bool> _readCommand(
    BluetoothProtocolClient client,
    BluetoothCommand command, {
    bool reportFailure = true,
  }) async {
    try {
      await client.readCommand(command);
      return true;
    } catch (error) {
      RcLogging.protocol(
        'read ${command.name} failed: $error',
        scope: 'RcAppController',
      );
    }
    if (reportFailure) _onError(_screenReadFailedMessage);
    return false;
  }

  Future<bool> _readControlMappingPayload(
    BluetoothProtocolClient client,
    List<int> payload, {
    bool reportFailure = true,
  }) async {
    try {
      await client.readCommandWithLenZeroPayload(
        BluetoothCommand.controlMapping,
        payload,
      );
      return true;
    } catch (error) {
      RcLogging.protocol(
        'read controlMapping(by channel) failed: $error',
        scope: 'RcAppController',
      );
    }
    if (reportFailure) _onError(_screenReadFailedMessage);
    return false;
  }

  int _controlMappingChannelIndex(String channel) {
    final n = int.tryParse(channel.replaceAll('CH', ''));
    if (n == null) return 2;
    return (n - 1).clamp(2, 10);
  }

  Future<void> _enqueueSession(
    Future<void> Function() task, {
    _SessionTaskPriority priority = _SessionTaskPriority.normal,
  }) {
    final completer = Completer<void>();
    final queued = _SessionTask(task: task, completer: completer);
    switch (priority) {
      case _SessionTaskPriority.high:
        _highPrioritySessionTasks.addLast(queued);
        break;
      case _SessionTaskPriority.normal:
        _normalPrioritySessionTasks.addLast(queued);
        break;
      case _SessionTaskPriority.low:
        _lowPrioritySessionTasks.addLast(queued);
        break;
    }
    unawaited(_drainSessionTasks());
    return completer.future;
  }

  Future<void> _drainSessionTasks() async {
    if (_sessionTaskRunnerActive) return;
    _sessionTaskRunnerActive = true;
    while (true) {
      final next = _dequeueSessionTask();
      if (next == null) {
        _sessionTaskRunnerActive = false;
        return;
      }
      try {
        await next.task();
        if (!next.completer.isCompleted) {
          next.completer.complete();
        }
      } catch (error, stackTrace) {
        if (!next.completer.isCompleted) {
          next.completer.completeError(error, stackTrace);
        }
      }
    }
  }

  _SessionTask? _dequeueSessionTask() {
    if (_highPrioritySessionTasks.isNotEmpty) {
      return _highPrioritySessionTasks.removeFirst();
    }
    if (_normalPrioritySessionTasks.isNotEmpty) {
      return _normalPrioritySessionTasks.removeFirst();
    }
    if (_lowPrioritySessionTasks.isNotEmpty) {
      return _lowPrioritySessionTasks.removeFirst();
    }
    return null;
  }

  Future<void> _restoreModelNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final names = prefs.getStringList(_modelNamesPrefsKey);
      if (names == null || names.isEmpty) return;
      final models = [...state.models];
      final limit = names.length < models.length ? names.length : models.length;
      for (var i = 0; i < limit; i++) {
        models[i] = models[i].copyWith(name: names[i]);
      }
      state = state.copyWith(models: models);
    } catch (error) {
      RcLogging.link(
        'restore model names failed: $error',
        scope: 'RcAppController',
      );
    }
  }

  Future<void> _persistModelNames(List<Model> models) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final names = models.map((e) => e.name).toList(growable: false);
      await prefs.setStringList(_modelNamesPrefsKey, names);
    } catch (error) {
      RcLogging.link(
        'persist model names failed: $error',
        scope: 'RcAppController',
      );
    }
  }

  bool _shouldDebounceIntent(RcAppIntent intent) {
    return intent is ChannelUpdatedIntent ||
        intent is ChannelTravelUpdatedIntent ||
        intent is ChannelReverseUpdatedIntent ||
        intent is SubTrimUpdatedIntent ||
        intent is FailsafeUpdatedIntent ||
        intent is DualRateUpdatedIntent ||
        intent is CurveValueUpdatedIntent ||
        intent is RadioSettingsUpdatedIntent ||
        intent is ControlMappingUpdatedIntent;
  }

  void _queueIntentDebounce(
    RcAppIntent intent, {
    Duration delay = _intentDebounceDelay,
  }) {
    _pendingDebouncedIntent = intent;
    _intentDebounceTimer?.cancel();
    _intentDebounceTimer = Timer(delay, _flushIntentDebounce);
  }

  void _flushIntentDebounce() {
    final intent = _pendingDebouncedIntent;
    _pendingDebouncedIntent = null;
    _intentDebounceTimer = null;
    if (intent == null || !state.bluetooth.isConnected) return;
    unawaited(
      _enqueueSession(() async {
        await _syncIntent(intent);
      }, priority: _SessionTaskPriority.high),
    );
  }

  void _clearIntentDebounce() {
    _pendingDebouncedIntent = null;
    _intentDebounceTimer?.cancel();
    _intentDebounceTimer = null;
  }

  Future<bool> _syncIntent(RcAppIntent intent, {RcAppState? source}) async {
    if (_blockWritesUntilReverseRead) {
      RcLogging.protocol(
        'skip write while waiting reverse read',
        scope: 'RcAppController',
      );
      return false;
    }
    final client = _client;
    if (client == null) return false;
    final writes = _adapter.writesForIntent(intent, source ?? state);
    if (intent is MixingSettingsUpdatedIntent) {
      if (writes.isEmpty) {
        RcLogging.link('混控写入为空', scope: 'BluetoothIO');
      } else {
        for (final req in writes) {
          RcLogging.link(
            '📤 混控发送 cmd=${req.command.name}(0x${req.command.id.toRadixString(16).toUpperCase()}) '
            'payload=${RcLogging.hex(req.payload, maxBytes: 24)}',
            scope: 'BluetoothIO',
          );
        }
      }
    }
    for (final req in writes) {
      try {
        final ack = await client.writeCommand(req.command, req.payload);
        if (!ack.isSuccess) {
          _onError(
            StateError('command ${req.command.name} ack failed: ${ack.code}'),
          );
          return false;
        }
      } catch (error) {
        _onError(error);
        return false;
      }
    }
    return true;
  }

  void _onFrame(BluetoothFrame frame) {
    final event = _adapter.decodeFrame(frame);
    state = _adapter.applyToState(state, event);
    final pinned = _pinnedControlMappingChannel;
    if (pinned != null && event.command == BluetoothCommand.controlMapping) {
      _showCachedControlMapping(pinned);
    }
  }

  void _onScan(List<BluetoothScanDevice> list) {
    final devices =
        _keepConnectedDeviceVisible(
          list.where(_allowScanDevice).map(_toDevice).toList(),
        )..sort((a, b) {
          if (a.connected == b.connected) return 0;
          return a.connected ? -1 : 1;
        });
    _setBluetooth(
      state.bluetooth.copyWith(
        devices: devices,
        isScanning: state.bluetooth.isScanning,
      ),
    );
    _tryAutoConnectLastDevice(devices);
  }

  List<BluetoothDevice> _keepConnectedDeviceVisible(
    List<BluetoothDevice> scannedDevices,
  ) {
    final connectedMac = state.bluetooth.connectedDeviceMac;
    if (connectedMac == null || connectedMac.isEmpty) return scannedDevices;
    final connectedKey = connectedMac.toLowerCase();
    for (final device in scannedDevices) {
      if (device.mac.toLowerCase() == connectedKey) return scannedDevices;
    }
    for (final device in state.bluetooth.devices) {
      if (device.mac.toLowerCase() != connectedKey) continue;
      return [...scannedDevices, device.copyWith(connected: true)];
    }
    return scannedDevices;
  }

  void _tryAutoConnectLastDevice(List<BluetoothDevice> devices) {
    if (_autoConnectingLastDevice ||
        state.bluetooth.isConnected ||
        state.bluetooth.isConnecting) {
      return;
    }
    final mac = _lastConnectedBluetoothMac;
    if (mac == null || mac.isEmpty) return;
    if (state.bluetooth.connectedDeviceMac == mac) return;
    BluetoothDevice? target;
    for (final device in devices) {
      if (device.mac == mac) {
        target = device;
        break;
      }
    }
    if (target == null) return;
    _autoConnectingLastDevice = true;
    final targetId = target.id;
    unawaited(() async {
      try {
        await _toggleConnection(targetId);
      } finally {
        _autoConnectingLastDevice = false;
      }
    }());
  }

  Future<void> _restoreLastConnectedBluetoothMac() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastConnectedBluetoothMac = prefs.getString(
        _lastConnectedBluetoothMacPrefsKey,
      );
      _tryAutoConnectLastDevice(state.bluetooth.devices);
    } catch (error) {
      RcLogging.link(
        'restore bluetooth mac failed: $error',
        scope: 'RcAppController',
      );
    }
  }

  Future<void> _persistLastConnectedBluetoothMac(String mac) async {
    if (mac.isEmpty) return;
    _lastConnectedBluetoothMac = mac;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastConnectedBluetoothMacPrefsKey, mac);
    } catch (error) {
      RcLogging.link(
        'persist bluetooth mac failed: $error',
        scope: 'RcAppController',
      );
    }
  }

  Future<void> _clearLastConnectedBluetoothMac() async {
    _lastConnectedBluetoothMac = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastConnectedBluetoothMacPrefsKey);
    } catch (error) {
      RcLogging.link(
        'clear bluetooth mac failed: $error',
        scope: 'RcAppController',
      );
    }
  }

  bool _allowScanDevice(BluetoothScanDevice device) {
    if (_transport.type != LinkType.ble) return true;
    return device.name.toUpperCase().startsWith(_bluetoothNamePrefix);
  }

  BluetoothDevice _toDevice(BluetoothScanDevice d) {
    final remoteId = d.remoteId.toLowerCase();
    _deviceIds[remoteId] ??= _nextId++;
    return BluetoothDevice(
      id: _deviceIds[remoteId]!,
      name: d.name,
      mac: d.remoteId,
      connected:
          d.remoteId.toLowerCase() ==
          state.bluetooth.connectedDeviceMac?.toLowerCase(),
      type: _transport.type == LinkType.usb ? 'usb' : 'ble',
      signal: _signalFromRssi(d.rssi),
    );
  }

  BluetoothDevice? _deviceById(int id) {
    for (final d in state.bluetooth.devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<BluetoothDevice> _markConnected(List<BluetoothDevice> devices, int? id) {
    final mapped = devices
        .map((d) => d.copyWith(connected: id != null && d.id == id))
        .toList();
    if (id == null) return mapped;
    mapped.sort((a, b) {
      if (a.connected == b.connected) return 0;
      return a.connected ? -1 : 1;
    });
    return mapped;
  }

  List<BluetoothDevice> _markConnectedByMac(
    List<BluetoothDevice> devices,
    String? mac,
  ) {
    final key = mac?.toLowerCase();
    final mapped = devices
        .map(
          (d) =>
              d.copyWith(connected: key != null && d.mac.toLowerCase() == key),
        )
        .toList();
    if (key == null) return mapped;
    mapped.sort((a, b) {
      if (a.connected == b.connected) return 0;
      return a.connected ? -1 : 1;
    });
    return mapped;
  }

  List<BluetoothDevice> _ensureConnectedDeviceVisible(
    List<BluetoothDevice> devices,
    BluetoothDevice target,
  ) {
    final key = target.mac.toLowerCase();
    for (final device in devices) {
      if (device.mac.toLowerCase() == key) return devices;
    }
    final next = [...devices, target.copyWith(connected: true)];
    next.sort((a, b) {
      if (a.connected == b.connected) return 0;
      return a.connected ? -1 : 1;
    });
    return next;
  }

  int _signalFromRssi(int rssi) {
    if (rssi >= -60) return 3;
    if (rssi >= -75) return 2;
    return 1;
  }

  void _onError(Object error) {
    final message = error.toString();
    RcLogging.link('error: $message', scope: 'RcAppController');
    if (message == _screenReadFailedMessage) {
      return;
    }
    _setBluetooth(state.bluetooth.copyWith(errorMessage: message));
  }

  void _setBluetooth(BluetoothSettings bluetooth) {
    state = state.copyWith(bluetooth: bluetooth);
  }

  RcAppState _reduce(RcAppState current, RcAppIntent intent) {
    if (intent is ChannelUpdatedIntent) {
      return _reduceChannel(current, intent.id, intent.next);
    }
    if (intent is ChannelTravelUpdatedIntent) {
      return _reduceChannel(current, intent.id, intent.next);
    }
    if (intent is ChannelReverseUpdatedIntent) {
      return _reduceChannel(current, intent.id, intent.next);
    }
    if (intent is SubTrimUpdatedIntent) {
      return _reduceChannel(current, intent.id, intent.next);
    }
    if (intent is FailsafeUpdatedIntent) {
      return _reduceChannel(current, intent.id, intent.next);
    }
    if (intent is DualRateUpdatedIntent) {
      return _reduceChannel(current, intent.id, intent.next);
    }
    if (intent is ModelSelectedIntent) {
      final models = current.models
          .map((m) => m.copyWith(active: m.id == intent.id))
          .toList();
      return current.copyWith(models: models);
    }
    if (intent is ModelRenamedIntent) {
      final models = current.models
          .map((m) => m.id == intent.id ? m.copyWith(name: intent.name) : m)
          .toList();
      return current.copyWith(models: models);
    }
    if (intent is RadioSettingsUpdatedIntent) {
      return current.copyWith(radioSettings: intent.next);
    }
    if (intent is MixingSettingsUpdatedIntent) {
      return _reduceMixing(current, intent.next);
    }
    if (intent is CurveSelectedIntent) {
      final idx = _curveIndex(intent.activeCurve);
      final value = idx < current.protocol.curveValues.length
          ? current.protocol.curveValues[idx]
          : current.curve.curveValue;
      return current.copyWith(
        curve: current.curve.copyWith(
          activeCurve: intent.activeCurve,
          curveValue: value,
        ),
      );
    }
    if (intent is CurveValueUpdatedIntent) {
      final idx = _curveIndex(current.curve.activeCurve);
      final values = [...current.protocol.curveValues];
      if (idx < values.length) values[idx] = intent.value.clamp(-100, 100);
      return current.copyWith(
        curve: current.curve.copyWith(curveValue: intent.value),
        protocol: current.protocol.copyWith(curveValues: values),
      );
    }
    if (intent is ControlMappingUpdatedIntent) {
      return _reduceControlMapping(current, intent.next);
    }
    if (intent is ControlMappingBatchUpdatedIntent) {
      return _reduceControlMappingBatch(current, intent.items);
    }
    if (intent is ControlMappingPreviewIntent) {
      return _reduceControlMapping(current, intent.next);
    }
    return current;
  }

  RcAppState _reduceChannel(RcAppState current, String id, ChannelState next) {
    final channels = current.channels
        .map((ch) => ch.id == id ? next : ch)
        .toList();
    return current.copyWith(channels: channels);
  }

  RcAppState _reduceMixing(RcAppState current, MixingSettings next) {
    final protocol = _nextProtocolForMixing(current, next);
    return current.copyWith(mixingSettings: next, protocol: protocol);
  }

  RcAppState _reduceControlMapping(
    RcAppState current,
    ControlMappingState next,
  ) {
    final normalized = _normalizeControlMapping(next);
    final mappings = Map<String, ControlMappingState>.from(
      current.controlMappings,
    );
    mappings[normalized.channel] = normalized;
    return current.copyWith(
      controlMapping: normalized,
      controlMappings: mappings,
    );
  }

  RcAppState _reduceControlMappingBatch(
    RcAppState current,
    List<ControlMappingState> items,
  ) {
    var next = current;
    for (final item in items) {
      next = _reduceControlMapping(next, item);
    }
    return next;
  }

  ControlMappingState _normalizeControlMapping(ControlMappingState next) {
    final type = normalizeControlTypeForChannel(next.channel, next.type);
    return next.copyWith(
      type: type,
      selectedState: type,
      availableStates: controlTypeOptionsForChannel(next.channel),
      controlType: controlTypeForSelection(next.channel, type),
    );
  }

  RcProtocolState _nextProtocolForMixing(
    RcAppState current,
    MixingSettings next,
  ) {
    final mode = next.activeMode;
    var protocol = current.protocol;
    if (mode.isEmpty) return protocol;
    if (next.enabled) {
      protocol = _withOnlyMixingEnabled(protocol, mode);
    }
    if (mode == '4WS') {
      final encoded = _encodeFourWheelMode(next.direction);
      protocol = protocol.copyWith(
        fourWheelSteer: protocol.fourWheelSteer.copyWith(
          enabled: next.enabled,
          channel: _uiChannelToProtocol(next.selectedChannel),
          ratio: next.ratio.clamp(0, 100),
          mode: encoded,
        ),
      );
    }
    if (mode == 'TRACK') {
      final ratio = next.ratio.abs().clamp(0, 100);
      var track = protocol.trackMixing;
      if (next.direction == 'SAME') {
        track = next.ratio >= 0
            ? track.copyWith(forwardRatio: ratio)
            : track.copyWith(backwardRatio: ratio);
      } else {
        track = next.ratio >= 0
            ? track.copyWith(rightRatio: ratio)
            : track.copyWith(leftRatio: ratio);
      }
      protocol = protocol.copyWith(
        trackMixing: track.copyWith(enabled: next.enabled),
      );
    }
    if (mode == 'DRIVE') {
      final ratios = _driveRatios(next.ratio, next.driveRatioSelectedSide);
      final driveMode = next.direction == 'REAR'
          ? 0
          : next.direction == 'MIXED'
          ? 1
          : 2;
      protocol = protocol.copyWith(
        driveMixing: protocol.driveMixing.copyWith(
          enabled: next.enabled,
          channel: _uiChannelToProtocol(next.selectedChannel),
          frontRatio: ratios.$1,
          rearRatio: ratios.$2,
          mode: driveMode,
        ),
      );
    }
    if (mode == 'BRAKE') {
      protocol = protocol.copyWith(
        brakeMixing: protocol.brakeMixing.copyWith(
          enabled: next.enabled,
          channel: _uiChannelToProtocol(next.selectedChannel),
          ratio: next.ratio.clamp(0, 100),
          curve: next.curve.clamp(-100, 100),
        ),
      );
    }
    return protocol;
  }

  RcProtocolState _withOnlyMixingEnabled(
    RcProtocolState protocol,
    String mode,
  ) {
    return protocol.copyWith(
      fourWheelSteer: protocol.fourWheelSteer.copyWith(enabled: mode == '4WS'),
      trackMixing: protocol.trackMixing.copyWith(enabled: mode == 'TRACK'),
      driveMixing: protocol.driveMixing.copyWith(enabled: mode == 'DRIVE'),
      brakeMixing: protocol.brakeMixing.copyWith(enabled: mode == 'BRAKE'),
    );
  }

  int _encodeFourWheelMode(String direction) {
    if (direction == '4WS_FRONT_OPPOSITE' || direction == 'OPPOSITE') return 1;
    if (direction == '4WS_REAR_SAME') return 2;
    if (direction == '4WS_REAR_OPPOSITE') return 3;
    return 0;
  }

  int _uiChannelToProtocol(String channel) {
    final n = int.tryParse(channel.replaceAll('CH', ''));
    if (n == null) return 2;
    return (n - 1).clamp(2, 10);
  }

  int _curveIndex(String activeCurve) {
    if (activeCurve == 'Steering') return 0;
    if (activeCurve == 'Brake') return 2;
    return 1;
  }

  (int, int) _driveRatios(int ratio, String side) {
    final clamped = ratio.clamp(-100, 100);
    if (side == 'F') return ((100 + clamped).clamp(0, 100), 100);
    return (100, (100 - clamped).clamp(0, 100));
  }
}

class _TransportProtocolChannel implements BluetoothProtocolChannel {
  _TransportProtocolChannel(this._transport);

  final LinkTransport _transport;

  @override
  Stream<List<int>> get bytes {
    return _transport.incomingBytes.map((chunk) {
      final cmd = _loggableRxCommand(chunk);
      if (cmd != null) {
        final cmdLabel =
            '${cmd.name}(0x${cmd.id.toRadixString(16).toUpperCase()})';
        final dataText =
            'bytes=${chunk.length} payload=${RcLogging.hex(chunk, maxBytes: 48)}';
        RcLogging.link('☎️ 设备发送 cmd=$cmdLabel $dataText', scope: 'BluetoothIO');
        unawaited(
          bluetoothLogStore.append(
            direction: 'RX',
            command: cmdLabel,
            dataText: dataText,
          ),
        );
      }
      return chunk;
    });
  }

  @override
  Future<void> send(List<int> bytes) {
    final cmd = _loggableCommand(bytes);
    if (cmd != null) {
      final cmdLabel =
          '${cmd.name}(0x${cmd.id.toRadixString(16).toUpperCase()})';
      final dataText =
          'bytes=${bytes.length} payload=${RcLogging.hex(bytes, maxBytes: 48)}';
      RcLogging.link('📱 手机发送 cmd=$cmdLabel $dataText', scope: 'BluetoothIO');
      unawaited(
        bluetoothLogStore.append(
          direction: 'TX',
          command: cmdLabel,
          dataText: dataText,
        ),
      );
    }
    return _transport.send(bytes);
  }

  BluetoothCommand? _loggableRxCommand(List<int> bytes) {
    final cmd = _loggableCommand(bytes);
    if (cmd == BluetoothCommand.channelDisplay ||
        cmd == BluetoothCommand.telemetryDisplay) {
      return null;
    }
    return cmd;
  }

  BluetoothCommand? _loggableCommand(List<int> bytes) {
    if (bytes.length < 3 || bytes.first != bluetoothFrameHead) return null;
    final cmd = BluetoothCommand.fromId(bytes[2]);
    if (cmd == null) return null;
    return cmd;
  }
}
